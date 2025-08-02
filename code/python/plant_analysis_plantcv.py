#!/usr/bin/env python3
"""
plant_analysis_plantcv.py

Analyzes plant features in a FarmBot image using PlantCV.
Saves masks, histograms, and pseudo-landmarks.
"""

import os
import argparse
from plantcv import plantcv as pcv

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--image",  help="Input image", default="data/soil_plant.jpg")
    p.add_argument("--outdir", help="Results folder", default="results/")
    p.add_argument("--debug",  help="Debug: print/plot/none", 
                   choices=["print","plot","none"], default="plot")
    return p.parse_args()

def main():
    args = parse_args()
    os.makedirs(args.outdir, exist_ok=True)
    pcv.params.debug = args.debug

    # Read image
    img, path, fname = pcv.read_image(filename=args.image)

    # 1) HSV S-channel threshold (soil vs green)
    s = pcv.rgb2gray_hsv(rgb_img=img, channel='s')
    s_thresh = pcv.threshold.binary(gray_img=s, threshold=85, max_value=255, object_type='light')
    s_mblur = pcv.median_blur(gray_img=s_thresh, ksize=5)

    # 2) Lab b-channel threshold (soil/perlite)
    b = pcv.rgb2gray_lab(rgb_img=img, channel='b')
    b_thresh = pcv.threshold.binary(gray_img=b, threshold=160, max_value=255, object_type='light')

    # 3) Combine S+Lab masks
    combined = pcv.logical_or(bin_img1=s_mblur, bin_img2=b_thresh)

    # 4) Mask original image
    masked = pcv.apply_mask(img=img, mask=combined, mask_color='white')

    # 5) Further refine via Lab a/b channels
    ma = pcv.rgb2gray_lab(rgb_img=masked, channel='a')
    mb = pcv.rgb2gray_lab(rgb_img=masked, channel='b')
    ma_dark  = pcv.threshold.binary(gray_img=ma, threshold=115, max_value=255, object_type='dark')
    ma_light = pcv.threshold.binary(gray_img=ma, threshold=135, max_value=255, object_type='light')
    mb_light = pcv.threshold.binary(gray_img=mb, threshold=128, max_value=255, object_type='light')
    ab1 = pcv.logical_or(bin_img1=ma_dark, bin_img2=mb_light)
    ab  = pcv.logical_or(bin_img1=ma_light, bin_img2=ab1)
    ab_fill = pcv.fill(bin_img=ab, size=200)
    ab_closed = pcv.closing(gray_img=ab_fill)

    # 6) Final mask apply
    final = pcv.apply_mask(img=masked, mask=ab_closed, mask_color='white')

    # 7) Object detection
    objs, hier = pcv.find_objects(img=img, mask=ab_closed)

    # 8) ROI (adjust coords as needed)
    roi, roi_h = pcv.roi.rectangle(img=final, x=100, y=100, h=200, w=200)

    # 9) Filter objects by ROI
    roi_objs, roi_h2, kept_mask, area = pcv.roi_objects(
        img=img, roi_contour=roi, roi_hierarchy=roi_h,
        object_contour=objs, obj_hierarchy=hier, roi_type='partial')

    # 10) Compose objects
    comp_obj, comp_mask = pcv.object_composition(
        img=img, contours=roi_objs, hierarchy=roi_h2)

    # 11) Analyze
    _ = pcv.analyze_object(img=img, obj=comp_obj, mask=comp_mask, label="plant")
    _ = pcv.analyze_bound_horizontal(img=img, obj=comp_obj, mask=comp_mask,
                                     line_position=370, label="hline")
    ch = pcv.analyze_color(rgb_img=img, mask=kept_mask, colorspaces='all', label="color")
    pcv.print_image(img=ch, 
                    filename=os.path.join(args.outdir, f"{fname}_color_hist.jpg"))

    # 12) Pseudolandmarks
    pcv.x_axis_pseudolandmarks(img=img, obj=comp_obj, mask=comp_mask, label="xmarks")
    pcv.y_axis_pseudolandmarks(img=img, obj=comp_obj, mask=comp_mask, label="ymarks")

    # 13) Save results
    pcv.outputs.save_results(filename=os.path.join(
        args.outdir, f"{fname}_plantcv_results.json"))

if __name__ == "__main__":
    main()
