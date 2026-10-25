#!/usr/bin/env python3
"""
Bit-Exact Integer and Floating-Point Reference Model for Traffic Light CNN.

This script implements:
1. The authoritative PyTorch TrafficLightCNN model architecture.
2. The bit-exact integer quantization pipeline matching the RTL hardware.
3. Verification utilities to export test vectors for end-to-end RTL verification.
"""

import os
import sys
import numpy as np
import torch
import torch.nn as nn

# Scale constants derived from training and calibration
INPUT_SCALE = 1.0 / 127.0
WEIGHT_SCALES = {
    'features.0': 0.002481956416227686,
    'features.3': 0.0022927128423855998,
    'features.6': 0.0022238887201144002,
    'classifier.1': 0.0028575691651171586,
    'classifier.3': 0.0018163315189166332,
}

ACTIVATION_SCALES = {
    'features.0': 0.01164362,
    'features.1': 0.01164362,
    'features.2': 0.01164362,
    'features.3': 0.02888882,
    'features.4': 0.02888882,
    'features.5': 0.02888882,
    'features.6': 0.06937264,
    'features.7': 0.06937264,
    'classifier.1': 0.19809496,
    'classifier.2': 0.19809496,
    'classifier.3': 0.20783915,
}

# Requantization parameters (SHIFT = 16)
# M1 = (INPUT_SCALE * W0_SCALE) / ACT0_SCALE = (1/127 * 0.002481956) / 0.01164362 = 0.001678427
# MULT1 = round(M1 * 65536) = 110
REQUANT_PARAMS = {
    'stage1': {'shift': 16, 'multiplier': 110},
    'stage2': {'shift': 16, 'multiplier': 61},
    'stage3': {'shift': 16, 'multiplier': 61},
}

CLASS_NAMES = ['Green', 'Red', 'Yellow']


def load_mem_hex_signed(path, bits=32):
    """Load hex values from a .mem file and convert to signed integers."""
    vals = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('//') or line.startswith('@'):
                continue
            v = int(line, 16)
            if v >= (1 << (bits - 1)):
                v -= (1 << bits)
            vals.append(v)
    return np.array(vals)


def write_mem_hex(path, values, bits=32):
    """Write integer values to a .mem file in two's complement hex format."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    mask = (1 << bits) - 1
    fmt = f"{{:0{bits // 4}X}}\n"
    with open(path, 'w') as f:
        for val in values.flatten():
            unsigned_val = int(val) & mask
            f.write(fmt.format(unsigned_val))


class TrafficLightCNN(nn.Module):
    """Authoritative checkpoint-compatible CNN architecture."""
    def __init__(self):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 16, kernel_size=3),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(16, 32, kernel_size=3),
            nn.ReLU(),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, kernel_size=3),
            nn.ReLU()
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(1024, 128),
            nn.ReLU(),
            nn.Linear(128, 3)
        )

    def forward(self, x):
        return self.classifier(self.features(x))


class IntegerCNNReference:
    """Bit-exact integer execution matching the RTL hardware architecture."""
    def __init__(self, mem_root='FPGA_Parameters/mem_files'):
        self.mem_root = mem_root
        self.load_parameters()

    def load_parameters(self):
        w_dir = os.path.join(self.mem_root, 'weights')
        b_dir = os.path.join(self.mem_root, 'biases')

        self.w0 = load_mem_hex_signed(os.path.join(w_dir, 'features_0_weight.mem'), 8).reshape(16, 3, 3, 3)
        self.b0 = load_mem_hex_signed(os.path.join(b_dir, 'features_0_bias.mem'), 32)

        self.w3 = load_mem_hex_signed(os.path.join(w_dir, 'features_3_weight.mem'), 8).reshape(32, 16, 3, 3)
        self.b3 = load_mem_hex_signed(os.path.join(b_dir, 'features_3_bias.mem'), 32)

        self.w6 = load_mem_hex_signed(os.path.join(w_dir, 'features_6_weight.mem'), 8).reshape(64, 32, 3, 3)
        self.b6 = load_mem_hex_signed(os.path.join(b_dir, 'features_6_bias.mem'), 32)

        self.w_fc1 = load_mem_hex_signed(os.path.join(w_dir, 'classifier_1_weight.mem'), 8).reshape(128, 1024)
        bias_fc1_path = os.path.join(b_dir, 'classifier_1_bias_int32.mem')
        if not os.path.exists(bias_fc1_path):
            bias_fc1_path = os.path.join(b_dir, 'classifier_1_bias.mem')
        self.b_fc1 = load_mem_hex_signed(bias_fc1_path, 32)

        self.w_fc2 = load_mem_hex_signed(os.path.join(w_dir, 'classifier_3_weight.mem'), 8).reshape(3, 128)
        self.b_fc2 = load_mem_hex_signed(os.path.join(b_dir, 'classifier_3_bias.mem'), 32)

    def requantize(self, values, shift, multiplier):
        """Hardware requantize with rounding and saturation to [-128, 127] / [0, 127]."""
        product = values.astype(np.int64) * multiplier
        if shift > 0:
            rounded = product + (1 << (shift - 1))
            scaled = rounded >> shift
        else:
            scaled = product
        return np.clip(scaled, -128, 127).astype(np.int8)

    def forward(self, img_raw):
        """
        Run complete integer forward pass on [3, 32, 32] image in [0, 127].
        Returns a dict of all intermediate and final outputs.
        """
        assert img_raw.shape == (3, 32, 32), f"Expected shape (3, 32, 32), got {img_raw.shape}"

        # Stage 1: Conv1 (32x32x3 -> 30x30x16)
        c1 = np.zeros((16, 30, 30), dtype=np.int32)
        for f in range(16):
            for y in range(30):
                for x in range(30):
                    c1[f, y, x] = np.sum(img_raw[:, y:y+3, x:x+3] * self.w0[f]) + self.b0[f]

        # ReLU1
        r1 = np.maximum(0, c1)

        # MaxPool1 (30x30x16 -> 15x15x16)
        p1 = np.zeros((16, 15, 15), dtype=np.int32)
        for f in range(16):
            for y in range(15):
                for x in range(15):
                    p1[f, y, x] = np.max(r1[f, 2*y:2*y+2, 2*x:2*x+2])

        # Requant1
        p1_params = REQUANT_PARAMS['stage1']
        req1 = self.requantize(p1, p1_params['shift'], p1_params['multiplier'])

        # Stage 2: Conv2 (15x15x16 -> 13x13x32)
        c2 = np.zeros((32, 13, 13), dtype=np.int32)
        for f in range(32):
            for y in range(13):
                for x in range(13):
                    c2[f, y, x] = np.sum(req1[:, y:y+3, x:x+3] * self.w3[f]) + self.b3[f]

        # ReLU2
        r2 = np.maximum(0, c2)

        # MaxPool2 (13x13x32 -> 6x6x32)
        p2 = np.zeros((32, 6, 6), dtype=np.int32)
        for f in range(32):
            for y in range(6):
                for x in range(6):
                    p2[f, y, x] = np.max(r2[f, 2*y:2*y+2, 2*x:2*x+2])

        # Requant2
        p2_params = REQUANT_PARAMS['stage2']
        req2 = self.requantize(p2, p2_params['shift'], p2_params['multiplier'])

        # Stage 3: Conv3 (6x6x32 -> 4x4x64)
        c3 = np.zeros((64, 4, 4), dtype=np.int32)
        for f in range(64):
            for y in range(4):
                for x in range(4):
                    c3[f, y, x] = np.sum(req2[:, y:y+3, x:x+3] * self.w6[f]) + self.b6[f]

        # ReLU3
        r3 = np.maximum(0, c3)

        # Requant3
        p3_params = REQUANT_PARAMS['stage3']
        req3 = self.requantize(r3, p3_params['shift'], p3_params['multiplier'])

        # Flatten in channel-first order (64, 4, 4) -> 1024
        flat = req3.flatten()

        # Stage 4: FC1 (1024 -> 128)
        fc1 = np.zeros(128, dtype=np.int32)
        for n in range(128):
            fc1[n] = np.sum(flat * self.w_fc1[n]) + self.b_fc1[n]

        # ReLU4
        r4 = np.maximum(0, fc1)

        # Stage 5: FC2 (128 -> 3)
        fc2 = np.zeros(3, dtype=np.int32)
        for c in range(3):
            fc2[c] = np.sum(r4 * self.w_fc2[c]) + self.b_fc2[c]

        # Stage 6: Argmax
        pred_class = int(np.argmax(fc2))

        return {
            'conv1': c1,
            'relu1': r1,
            'pool1': p1,
            'requant1': req1,
            'conv2': c2,
            'relu2': r2,
            'pool2': p2,
            'requant2': req2,
            'conv3': c3,
            'relu3': r3,
            'requant3': req3,
            'flatten': flat,
            'fc1': fc1,
            'relu4': r4,
            'fc2': fc2,
            'predicted_class': pred_class,
            'class_name': CLASS_NAMES[pred_class]
        }


def build_pytorch_model(ref):
    """Build PyTorch model with weights scaled to FP32."""
    model = TrafficLightCNN()
    s_w0 = WEIGHT_SCALES['features.0']
    s_w3 = WEIGHT_SCALES['features.3']
    s_w6 = WEIGHT_SCALES['features.6']
    s_w_fc1 = WEIGHT_SCALES['classifier.1']
    s_w_fc2 = WEIGHT_SCALES['classifier.3']

    state_dict = {
        'features.0.weight': torch.tensor(ref.w0 * s_w0, dtype=torch.float32),
        'features.0.bias': torch.tensor(ref.b0 * (INPUT_SCALE * s_w0), dtype=torch.float32),
        'features.3.weight': torch.tensor(ref.w3 * s_w3, dtype=torch.float32),
        'features.3.bias': torch.tensor(ref.b3 * (ACTIVATION_SCALES['features.2'] * s_w3), dtype=torch.float32),
        'features.6.weight': torch.tensor(ref.w6 * s_w6, dtype=torch.float32),
        'features.6.bias': torch.tensor(ref.b6 * (ACTIVATION_SCALES['features.5'] * s_w6), dtype=torch.float32),
        'classifier.1.weight': torch.tensor(ref.w_fc1 * s_w_fc1, dtype=torch.float32),
        'classifier.1.bias': torch.tensor(ref.b_fc1 * (ACTIVATION_SCALES['features.7'] * s_w_fc1), dtype=torch.float32),
        'classifier.3.weight': torch.tensor(ref.w_fc2 * s_w_fc2, dtype=torch.float32),
        'classifier.3.bias': torch.tensor(ref.b_fc2 * (ACTIVATION_SCALES['classifier.2'] * s_w_fc2), dtype=torch.float32)
    }
    model.load_state_dict(state_dict)
    model.eval()
    return model


if __name__ == '__main__':
    print("Initializing Integer Reference CNN Model...")
    ref = IntegerCNNReference()
    py_model = build_pytorch_model(ref)

    # Test with real CARLA image
    img_path = 'FPGA_Parameters/mem_files/conv1_full_test/conv1_input.mem'
    if os.path.exists(img_path):
        img_raw = np.array([int(line.strip(), 16) for line in open(img_path) if line.strip()]).reshape(3, 32, 32)
        print(f"Loaded image from {img_path}, shape={img_raw.shape}, min={img_raw.min()}, max={img_raw.max()}")

        res = ref.forward(img_raw)
        print(f"Integer Inference -> Predicted Class: {res['predicted_class']} ({res['class_name']})")
        print(f"FC2 Scores: {res['fc2']}")

        # PyTorch FP32
        t = torch.tensor((img_raw / 127.0).reshape(1, 3, 32, 32), dtype=torch.float32)
        with torch.no_grad():
            py_logits = py_model(t).numpy()[0]
        py_pred = int(np.argmax(py_logits))
        print(f"PyTorch FP32 -> Predicted Class: {py_pred} ({CLASS_NAMES[py_pred]})")
        print(f"PyTorch Logits: {py_logits}")

        assert res['predicted_class'] == py_pred, "Class prediction mismatch!"
        print("PASS: Integer Reference and PyTorch FP32 agree on predicted class!")
