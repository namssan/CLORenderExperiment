#import "Utility.h"

UIBezierPath *BuildBunnyPath()
{
    UIBezierPath *shapePath = [UIBezierPath bezierPath];
    [shapePath moveToPoint: CGPointMake(392.05, 150.53)];
    [shapePath addCurveToPoint: CGPointMake(343.11, 129.56) controlPoint1: CGPointMake(379.34, 133.37) controlPoint2: CGPointMake(359, 133.37)];
    [shapePath addCurveToPoint: CGPointMake(305.61, 71.72) controlPoint1: CGPointMake(341.2, 119.39) controlPoint2: CGPointMake(316.41, 71.08)];
    [shapePath addCurveToPoint: CGPointMake(304.34, 100.96) controlPoint1: CGPointMake(294.8, 72.35) controlPoint2: CGPointMake(302.43, 79.35)];
    [shapePath addCurveToPoint: CGPointMake(283.36, 84.43) controlPoint1: CGPointMake(299.25, 95.24) controlPoint2: CGPointMake(287.81, 73.63)];
    [shapePath addCurveToPoint: CGPointMake(301.79, 154.99) controlPoint1: CGPointMake(272.42, 111.01) controlPoint2: CGPointMake(302.43, 148.63)];
    [shapePath addCurveToPoint: CGPointMake(287.17, 191.85) controlPoint1: CGPointMake(301.16, 161.34) controlPoint2: CGPointMake(299, 186.78)];
    [shapePath addCurveToPoint: CGPointMake(194.38, 221.09) controlPoint1: CGPointMake(282.72, 193.76) controlPoint2: CGPointMake(240.78, 195.66)];
    [shapePath addCurveToPoint: CGPointMake(128.27, 320.25) controlPoint1: CGPointMake(147.97, 246.51) controlPoint2: CGPointMake(138.44, 282.11)];
    [shapePath addCurveToPoint: CGPointMake(124.75, 348.92) controlPoint1: CGPointMake(125.53, 330.51) controlPoint2: CGPointMake(124.54, 340.12)];
    [shapePath addCurveToPoint: CGPointMake(118.34, 358.13) controlPoint1: CGPointMake(122.92, 350.31) controlPoint2: CGPointMake(120.74, 353.02)];
    [shapePath addCurveToPoint: CGPointMake(136.06, 388.68) controlPoint1: CGPointMake(112.42, 370.73) controlPoint2: CGPointMake(123.06, 383.91)];
    [shapePath addCurveToPoint: CGPointMake(144.8, 399.06) controlPoint1: CGPointMake(138.8, 392.96) controlPoint2: CGPointMake(141.79, 396.49)];
    [shapePath addCurveToPoint: CGPointMake(210.9, 408.6) controlPoint1: CGPointMake(158.14, 410.5) controlPoint2: CGPointMake(205.18, 406.69)];
    [shapePath addCurveToPoint: CGPointMake(240.78, 417.5) controlPoint1: CGPointMake(216.62, 410.5) controlPoint2: CGPointMake(234.41, 417.5)];
    [shapePath addCurveToPoint: CGPointMake(267.47, 411.78) controlPoint1: CGPointMake(247.13, 417.5) controlPoint2: CGPointMake(267.47, 419.4)];
    [shapePath addCurveToPoint: CGPointMake(250.3, 385.71) controlPoint1: CGPointMake(267.47, 394.61) controlPoint2: CGPointMake(250.3, 385.71)];
    [shapePath addCurveToPoint: CGPointMake(274.46, 371.73) controlPoint1: CGPointMake(250.3, 385.71) controlPoint2: CGPointMake(260.48, 379.99)];
    [shapePath addCurveToPoint: CGPointMake(302.43, 350.12) controlPoint1: CGPointMake(288.45, 363.47) controlPoint2: CGPointMake(297.34, 350.76)];
    [shapePath addCurveToPoint: CGPointMake(318.32, 389.53) controlPoint1: CGPointMake(312.22, 348.89) controlPoint2: CGPointMake(311.33, 381.9)];
    [shapePath addCurveToPoint: CGPointMake(341.84, 421.94) controlPoint1: CGPointMake(325.32, 397.15) controlPoint2: CGPointMake(332.15, 418.51)];
    [shapePath addCurveToPoint: CGPointMake(375.53, 413.68) controlPoint1: CGPointMake(349.08, 424.51) controlPoint2: CGPointMake(373.62, 421.31)];
    [shapePath addCurveToPoint: CGPointMake(367.26, 398.43) controlPoint1: CGPointMake(377.43, 406.06) controlPoint2: CGPointMake(372.35, 405.42)];
    [shapePath addCurveToPoint: CGPointMake(361.54, 352.66) controlPoint1: CGPointMake(362.18, 391.43) controlPoint2: CGPointMake(356.46, 363.47)];
    [shapePath addCurveToPoint: CGPointMake(378.07, 277.66) controlPoint1: CGPointMake(366.63, 341.86) controlPoint2: CGPointMake(376.8, 296.73)];
    [shapePath addCurveToPoint: CGPointMake(388.87, 220.45) controlPoint1: CGPointMake(379.34, 258.59) controlPoint2: CGPointMake(378.7, 245.88)];
    [shapePath addCurveToPoint: CGPointMake(411.12, 189.31) controlPoint1: CGPointMake(405.4, 214.1) controlPoint2: CGPointMake(410.48, 197.57)];
    [shapePath addCurveToPoint: CGPointMake(392.05, 150.53) controlPoint1: CGPointMake(411.76, 181.04) controlPoint2: CGPointMake(404.76, 167.7)];
    [shapePath closePath];
    return shapePath;
}

// http://pastie.org/private/7i0lgpfqtlkihbjyn0ba
// http://imgur.com/Po3uoIy
UIBezierPath *BuildMoofPath()
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint: CGPointMake(107, 66)];
    [path addCurveToPoint: CGPointMake(119, 69) controlPoint1: CGPointMake(113.17, 65.65) controlPoint2: CGPointMake(116.61, 65.38)];
    [path addCurveToPoint: CGPointMake(118, 100) controlPoint1: CGPointMake(118.67, 79.33) controlPoint2: CGPointMake(118.33, 89.67)];
    [path addCurveToPoint: CGPointMake(140, 114) controlPoint1: CGPointMake(125.33, 104.67) controlPoint2: CGPointMake(132.67, 109.33)];
    [path addCurveToPoint: CGPointMake(240, 105) controlPoint1: CGPointMake(169.22, 124.94) controlPoint2: CGPointMake(219.91, 117.23)];
    [path addCurveToPoint: CGPointMake(261, 76) controlPoint1: CGPointMake(252.29, 97.52) controlPoint2: CGPointMake(251.99, 86.39)];
    [path addCurveToPoint: CGPointMake(267, 78) controlPoint1: CGPointMake(263, 76.67) controlPoint2: CGPointMake(265, 77.33)];
    [path addCurveToPoint: CGPointMake(255, 145) controlPoint1: CGPointMake(276.45, 112.7) controlPoint2: CGPointMake(260.16, 119.11)];
    [path addCurveToPoint: CGPointMake(262, 188) controlPoint1: CGPointMake(257.33, 159.33) controlPoint2: CGPointMake(259.67, 173.67)];
    [path addCurveToPoint: CGPointMake(208, 232) controlPoint1: CGPointMake(268.07, 224.31) controlPoint2: CGPointMake(240.23, 239.3)];
    [path addCurveToPoint: CGPointMake(206, 225) controlPoint1: CGPointMake(207.33, 229.67) controlPoint2: CGPointMake(206.67, 227.33)];
    [path addCurveToPoint: CGPointMake(220, 192) controlPoint1: CGPointMake(217.21, 215.24) controlPoint2: CGPointMake(226.39, 211.63)];
    [path addCurveToPoint: CGPointMake(127, 186) controlPoint1: CGPointMake(197.32, 181.14) controlPoint2: CGPointMake(155.61, 179.26)];
    [path addCurveToPoint: CGPointMake(78, 230) controlPoint1: CGPointMake(126.93, 214.62) controlPoint2: CGPointMake(110.79, 250.16)];
    [path addCurveToPoint: CGPointMake(86, 203) controlPoint1: CGPointMake(76.79, 220.05) controlPoint2: CGPointMake(83.57, 212.84)];
    [path addCurveToPoint: CGPointMake(85, 132) controlPoint1: CGPointMake(90.93, 183.08) controlPoint2: CGPointMake(90.79, 150.81)];
    [path addCurveToPoint: CGPointMake(28, 121) controlPoint1: CGPointMake(60.95, 132.68) controlPoint2: CGPointMake(39.36, 132.88)];
    [path addCurveToPoint: CGPointMake(57, 91) controlPoint1: CGPointMake(27.34, 95.81) controlPoint2: CGPointMake(48.07, 104.89)];
    [path addCurveToPoint: CGPointMake(60, 73) controlPoint1: CGPointMake(58, 85) controlPoint2: CGPointMake(59, 79)];
    [path addCurveToPoint: CGPointMake(85, 76) controlPoint1: CGPointMake(66.31, 61.96) controlPoint2: CGPointMake(80.38, 68.36)];
    [path addCurveToPoint: CGPointMake(107, 66) controlPoint1: CGPointMake(93.79, 75.13) controlPoint2: CGPointMake(101.6, 70.61)];
    [path closePath];
    [path moveToPoint: CGPointMake(116, 69)];
    [path addCurveToPoint: CGPointMake(84, 78) controlPoint1: CGPointMake(104.12, 69.8) controlPoint2: CGPointMake(92.62, 83.34)];
    [path addCurveToPoint: CGPointMake(77, 72) controlPoint1: CGPointMake(81.67, 76) controlPoint2: CGPointMake(79.33, 74)];
    [path addCurveToPoint: CGPointMake(67, 72) controlPoint1: CGPointMake(73.67, 72) controlPoint2: CGPointMake(70.33, 72)];
    [path addCurveToPoint: CGPointMake(60, 93) controlPoint1: CGPointMake(60.55, 76.74) controlPoint2: CGPointMake(64.31, 86.1)];
    [path addCurveToPoint: CGPointMake(32, 111) controlPoint1: CGPointMake(54.17, 102.33) controlPoint2: CGPointMake(37.4, 101.45)];
    [path addCurveToPoint: CGPointMake(32, 121) controlPoint1: CGPointMake(32, 114.33) controlPoint2: CGPointMake(32, 117.67)];
    [path addCurveToPoint: CGPointMake(88, 129) controlPoint1: CGPointMake(44.53, 129.24) controlPoint2: CGPointMake(66.88, 129.21)];
    [path addCurveToPoint: CGPointMake(109, 172) controlPoint1: CGPointMake(93.2, 149.04) controlPoint2: CGPointMake(120.58, 148.18)];
    [path addCurveToPoint: CGPointMake(92, 176) controlPoint1: CGPointMake(103.33, 173.33) controlPoint2: CGPointMake(97.67, 174.67)];
    [path addCurveToPoint: CGPointMake(83, 230) controlPoint1: CGPointMake(91.91, 195.18) controlPoint2: CGPointMake(78.84, 222.44)];
    [path addCurveToPoint: CGPointMake(85, 230) controlPoint1: CGPointMake(83.67, 230) controlPoint2: CGPointMake(84.33, 230)];
    [path addCurveToPoint: CGPointMake(127, 183) controlPoint1: CGPointMake(131.62, 242.71) controlPoint2: CGPointMake(110.92, 195.36)];
    [path addCurveToPoint: CGPointMake(223, 190) controlPoint1: CGPointMake(149.67, 169.94) controlPoint2: CGPointMake(207.14, 180.38)];
    [path addCurveToPoint: CGPointMake(209, 226) controlPoint1: CGPointMake(228.64, 206.57) controlPoint2: CGPointMake(224.64, 221.84)];
    [path addCurveToPoint: CGPointMake(210, 229) controlPoint1: CGPointMake(209.33, 227) controlPoint2: CGPointMake(209.67, 228)];
    [path addCurveToPoint: CGPointMake(258, 184) controlPoint1: CGPointMake(240.81, 233.96) controlPoint2: CGPointMake(265.07, 221.63)];
    [path addCurveToPoint: CGPointMake(251, 147) controlPoint1: CGPointMake(255.67, 171.67) controlPoint2: CGPointMake(253.33, 159.33)];
    [path addCurveToPoint: CGPointMake(262, 79) controlPoint1: CGPointMake(253.73, 128.51) controlPoint2: CGPointMake(281.22, 99.39)];
    [path addCurveToPoint: CGPointMake(230, 113) controlPoint1: CGPointMake(260.12, 98.13) controlPoint2: CGPointMake(245.13, 107.06)];
    [path addCurveToPoint: CGPointMake(174, 146) controlPoint1: CGPointMake(229.65, 133.05) controlPoint2: CGPointMake(198.37, 155.24)];
    [path addCurveToPoint: CGPointMake(150, 119) controlPoint1: CGPointMake(166, 137) controlPoint2: CGPointMake(158, 128)];
    [path addCurveToPoint: CGPointMake(101, 96) controlPoint1: CGPointMake(138.77, 111.56) controlPoint2: CGPointMake(109.21, 105.11)];
    [path addCurveToPoint: CGPointMake(116, 69) controlPoint1: CGPointMake(103.48, 82.21) controlPoint2: CGPointMake(113.99, 82.77)];
    [path closePath];
    [path moveToPoint: CGPointMake(76, 93)];
    [path addCurveToPoint: CGPointMake(82, 93) controlPoint1: CGPointMake(78, 93) controlPoint2: CGPointMake(80, 93)];
    [path addCurveToPoint: CGPointMake(82, 98) controlPoint1: CGPointMake(82, 94.67) controlPoint2: CGPointMake(82, 96.33)];
    [path addCurveToPoint: CGPointMake(76, 98) controlPoint1: CGPointMake(80, 98) controlPoint2: CGPointMake(78, 98)];
    [path addCurveToPoint: CGPointMake(76, 93) controlPoint1: CGPointMake(76, 96.33) controlPoint2: CGPointMake(76, 94.67)];
    [path closePath];
    return path;
}


// By request of Maurice Sharpe, who thought people would like to see
// the source code for this one.
UIImage *ColorWheel(CGFloat side, BOOL useBorder)
{
    UIBezierPath *path;
    CGSize size = CGSizeMake(side, side);
    CGPoint center = CGPointMake(side / 2, side / 2);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    for (int i = 0; i < 6; i++)
    {
        CGFloat width = side / 14;
        CGFloat radius = width * (i + 1.0f);
        CGFloat saturation = (i + 1.0f) / 6.0f;
        
        for (CGFloat theta = 0; theta < M_PI * 2; theta += (M_PI / 6))
        {
            CGFloat hue = theta / (2 * M_PI);
            UIColor *c = [UIColor colorWithHue:hue saturation:saturation brightness:1 alpha:1.0f];
            
            CGFloat angle = (theta - M_PI_2);
            if (angle < 0)
                angle += 2 * M_PI;
            
            path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:angle endAngle:(angle + M_PI / 6) clockwise:YES];
            path.lineWidth = width;
            
            [c set];
            [path stroke];
        }
    }
    
    if (useBorder)
    {
        [[UIColor blackColor] set];
        path = [UIBezierPath bezierPathWithArcCenter:center radius:(side / 2) - (side / 28) startAngle:0 endAngle:2 * M_PI clockwise:YES];
        path.lineWidth = 4;
        [path stroke];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return image;
}

