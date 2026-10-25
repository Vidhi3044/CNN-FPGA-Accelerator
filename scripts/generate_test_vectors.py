#!/usr/bin/env python3
"""
Generate comprehensive test vectors for end-to-end RTL verification.
Generates test cases for Green, Red, and Yellow traffic light classes.
"""

import os
import sys
import numpy as np
from PIL import Image
from cnn_reference import IntegerCNNReference, write_mem_hex, CLASS_NAMES

def main():
    ref = IntegerCNNReference()
    output_dir = 'FPGA_Parameters/test_cases'
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs('simulations/test_images', exist_ok=True)

    test_cases = []

    # Case 0: Real CARLA image from conv1_input.mem
    real_path = 'FPGA_Parameters/mem_files/conv1_full_test/conv1_input.mem'
    img_real = np.array([int(line.strip(), 16) for line in open(real_path) if line.strip()]).reshape(3, 32, 32)
    test_cases.append(('case0_real_green', img_real, 0))

    # Case 1: Red traffic light (Top circle bright red, dark body)
    img_red = np.full((3, 32, 32), 12, dtype=np.int32)
    # Traffic light housing
    img_red[:, 2:30, 8:24] = 20
    # Red bulb (top, y: 5..11, x: 12..20)
    for y in range(5, 12):
        for x in range(12, 21):
            if (y - 8)**2 + (x - 16)**2 <= 16:
                img_red[0, y, x] = 125
                img_red[1, y, x] = 15
                img_red[2, y, x] = 10
    test_cases.append(('case1_red', img_red, 1))

    # Case 2: Yellow traffic light (Middle circle yellow, dark body)
    img_yellow = np.full((3, 32, 32), 12, dtype=np.int32)
    img_yellow[:, 2:30, 8:24] = 20
    # Yellow bulb (middle, y: 13..19, x: 12..20)
    for y in range(13, 20):
        for x in range(12, 21):
            if (y - 16)**2 + (x - 16)**2 <= 16:
                img_yellow[0, y, x] = 125
                img_yellow[1, y, x] = 115
                img_yellow[2, y, x] = 10
    test_cases.append(('case2_yellow', img_yellow, 2))

    # Case 3: Green traffic light (Bottom circle bright green, dark body)
    img_green = np.full((3, 32, 32), 12, dtype=np.int32)
    img_green[:, 2:30, 8:24] = 20
    # Green bulb (bottom, y: 21..27, x: 12..20)
    for y in range(21, 28):
        for x in range(12, 21):
            if (y - 24)**2 + (x - 16)**2 <= 16:
                img_green[0, y, x] = 30
                img_green[1, y, x] = 125
                img_green[2, y, x] = 40
    test_cases.append(('case3_green', img_green, 0))

    manifest = []

    for name, img, expected_label in test_cases:
        case_dir = os.path.join(output_dir, name)
        os.makedirs(case_dir, exist_ok=True)

        res = ref.forward(img)
        pred_label = res['predicted_class']
        scores = res['fc2']

        print(f"[{name}] Expected: {expected_label} ({CLASS_NAMES[expected_label]}) | "
              f"Predicted: {pred_label} ({CLASS_NAMES[pred_label]}) | Scores: {scores}")

        assert pred_label == expected_label, f"Mismatch for {name}: expected {expected_label}, got {pred_label}"

        # Write memory files
        write_mem_hex(os.path.join(case_dir, 'input_image.mem'), img, bits=8)
        write_mem_hex(os.path.join(case_dir, 'expected_conv1.mem'), res['conv1'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_pool1.mem'), res['pool1'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_requant1.mem'), res['requant1'], bits=8)
        write_mem_hex(os.path.join(case_dir, 'expected_conv2.mem'), res['conv2'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_pool2.mem'), res['pool2'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_requant2.mem'), res['requant2'], bits=8)
        write_mem_hex(os.path.join(case_dir, 'expected_conv3.mem'), res['conv3'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_requant3.mem'), res['requant3'], bits=8)
        write_mem_hex(os.path.join(case_dir, 'expected_flatten.mem'), res['flatten'], bits=8)
        write_mem_hex(os.path.join(case_dir, 'expected_fc1.mem'), res['fc1'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_fc2.mem'), res['fc2'], bits=32)
        write_mem_hex(os.path.join(case_dir, 'expected_class.mem'), np.array([pred_label]), bits=8)

        # Save visualization image
        img_hwc = np.transpose(img, (1, 2, 0)).astype(np.uint8) * 2
        im_vis = Image.fromarray(np.clip(img_hwc, 0, 255).astype(np.uint8))
        im_vis.save(f'simulations/test_images/{name}.png')

        manifest.append({
            'name': name,
            'expected_label': expected_label,
            'predicted_label': pred_label,
            'class_name': CLASS_NAMES[pred_label],
            'scores': scores.tolist()
        })

    print(f"\nSuccessfully generated {len(test_cases)} comprehensive test cases in {output_dir}/")


if __name__ == '__main__':
    main()
