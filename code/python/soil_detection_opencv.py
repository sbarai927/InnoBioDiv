#!/usr/bin/env python3
"""
soil_detection_opencv.py

Detects soil (brown + perlite) vs. plant (green) in a FarmBot image using OpenCV.
Outputs a target coordinate for dynamic watering.
"""

import cv2
import numpy as np

# Calibration constants (camera-to-nozzle offset in mm and mm-per-pixel)
X_OFFSET_MM = 32.51      # X axis adjustment (nozzle vs. camera)
Y_OFFSET_MM = 43         # Y axis adjustment
MM_PER_PIXEL = 0.3078    # Scale: mm of real world per image pixel

def crop_to_pot(img, center_offset=(0,0), radius_factor=0.27):
    """Mask out everything outside the circular pot region."""
    h, w = img.shape[:2]
    cx = int(w/2 + center_offset[0])
    cy = int(h/2 + center_offset[1])
    radius = int(radius_factor * w)
    mask = np.zeros((h, w), dtype=np.uint8)
    cv2.circle(mask, (cx, cy), radius, 255, -1)
    cropped = img.copy()
    cropped[mask == 0] = (255,255,255)
    return cropped

def find_watering_target(image_path, center_offset=(23,-12)):
    # 1) Load and crop
    img = cv2.imread(image_path)
    pot = crop_to_pot(img, center_offset=center_offset)

    # 2) Convert to HSV
    hsv = cv2.cvtColor(pot, cv2.COLOR_BGR2HSV)

    # 3) Soil & perlite color ranges (tune as needed)
    lower_soil    = np.array([0, 12, 31], dtype=np.uint8)
    upper_soil    = np.array([43, 78, 161], dtype=np.uint8)
    lower_perlite = np.array([43,  0,229], dtype=np.uint8)
    upper_perlite = np.array([179,45,255], dtype=np.uint8)

    # 4) Create masks
    mask_soil    = cv2.inRange(hsv, lower_soil, lower_soil)
    mask_soil    = cv2.inRange(hsv, lower_soil, upper_soil)
    mask_perl    = cv2.inRange(hsv, lower_perlite, upper_perlite)
    combined     = cv2.bitwise_or(mask_soil, mask_perl)

    # 5) Find largest contour
    cnts, _ = cv2.findContours(combined, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        raise ValueError("No soil region found")
    largest = max(cnts, key=cv2.contourArea)
    M = cv2.moments(largest)
    if M["m00"] == 0:
        x,y,w,h = cv2.boundingRect(largest)
        cx, cy = x+w//2, y+h//2
    else:
        cx, cy = int(M["m10"]/M["m00"]), int(M["m01"]/M["m00"])

    # 6) Draw target for debug
    cv2.circle(pot, (cx,cy), 8, (0,0,255), -1)
    cv2.imwrite("debug_soil_target.jpg", pot)

    # 7) Convert to FarmBot coords (requires knowing camera X,Y at capture time)
    FARMBOT_X = 100.0   # placeholder: actual X when image was taken
    FARMBOT_Y = 200.0   # placeholder: actual Y when image was taken
    dx_mm = (cx - pot.shape[1]/2) * MM_PER_PIXEL
    dy_mm = (cy - pot.shape[0]/2) * MM_PER_PIXEL
    target_x = FARMBOT_X - X_OFFSET_MM + dx_mm
    target_y = FARMBOT_Y + Y_OFFSET_MM + dy_mm

    return target_x, target_y

if __name__ == "__main__":
    tx, ty = find_watering_target("data/soil_plant.jpg")
    print(f"Water here → X={tx:.1f}  Y={ty:.1f}")
