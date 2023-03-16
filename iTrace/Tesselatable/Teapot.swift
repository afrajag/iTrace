//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class Teapot: BezierMesh {
    static var PATCHES: [[Float]]?

    required init() {
        super.init(Teapot.initTeapot())
    }

    static func initTeapot() -> [[Float]] {
        if PATCHES == nil {
            PATCHES = [[-80.0, 0.0, 30.0, -80.0, -44.7999992370605, 30.0, -44.7999992370605, -80.0, 30.0, 0.0, -80.0, 30.0, -80.0, 0.0, 12.0, -80.0, -44.7999992370605, 12.0, -44.7999992370605, -80.0, 12.0, 0.0, -80.0, 12.0, -60.0, 0.0, 3.0, -60.0, -33.5999984741211, 3.0, -33.5999984741211, -60.0, 3.0, 0.0, -60.0, 3.0, -60.0, 0.0, 0.0, -60.0, -33.5999984741211, 0.0, -33.5999984741211, -60.0, 0.0, 0.0, -60.0, 0.0], [0.0, -80.0, 30.0, 44.7999992370605, -80.0, 30.0, 80.0, -44.7999992370605, 30.0, 80.0, 0.0, 30.0, 0.0, -80.0, 12.0, 44.7999992370605, -80.0, 12.0, 80.0, -44.7999992370605, 12.0, 80.0, 0.0, 12.0, 0.0, -60.0, 3.0, 33.5999984741211, -60.0, 3.0, 60.0, -33.5999984741211, 3.0, 60.0, 0.0, 3.0, 0.0, -60.0, 0.0, 33.5999984741211, -60.0, 0.0, 60.0, -33.5999984741211, 0.0, 60.0, 0.0, 0.0], [-60.0, 0.0, 90.0, -60.0, -33.5999984741211, 90.0, -33.5999984741211, -60.0, 90.0, 0.0, -60.0, 90.0, -70.0, 0.0, 69.0, -70.0, -39.2000007629395, 69.0, -39.2000007629395, -70.0, 69.0, 0.0, -70.0, 69.0, -80.0, 0.0, 48.0, -80.0, -44.7999992370605, 48.0, -44.7999992370605, -80.0, 48.0, 0.0, -80.0, 48.0, -80.0, 0.0, 30.0, -80.0, -44.7999992370605, 30.0, -44.7999992370605, -80.0, 30.0, 0.0, -80.0, 30.0], [0.0, -60.0, 90.0, 33.5999984741211, -60.0, 90.0, 60.0, -33.5999984741211, 90.0, 60.0, 0.0, 90.0, 0.0, -70.0, 69.0, 39.2000007629395, -70.0, 69.0, 70.0, -39.2000007629395, 69.0, 70.0, 0.0, 69.0, 0.0, -80.0, 48.0, 44.7999992370605, -80.0, 48.0, 80.0, -44.7999992370605, 48.0, 80.0, 0.0, 48.0, 0.0, -80.0, 30.0, 44.7999992370605, -80.0, 30.0, 80.0, -44.7999992370605, 30.0, 80.0, 0.0, 30.0], [-56.0, 0.0, 90.0, -56.0, -31.3600006103516, 90.0, -31.3600006103516, -56.0, 90.0, 0.0, -56.0, 90.0, -53.5, 0.0, 95.25, -53.5, -29.9599990844727, 95.25, -29.9599990844727, -53.5, 95.25, 0.0, -53.5, 95.25, -57.5, 0.0, 95.25, -57.5, -32.2000007629395, 95.25, -32.2000007629395, -57.5, 95.25, 0.0, -57.5, 95.25, -60.0, 0.0, 90.0, -60.0, -33.5999984741211, 90.0, -33.5999984741211, -60.0, 90.0, 0.0, -60.0, 90.0], [0.0, -56.0, 90.0, 31.3600006103516, -56.0, 90.0, 56.0, -31.3600006103516, 90.0, 56.0, 0.0, 90.0, 0.0, -53.5, 95.25, 29.9599990844727, -53.5, 95.25, 53.5, -29.9599990844727, 95.25, 53.5, 0.0, 95.25, 0.0, -57.5, 95.25, 32.2000007629395, -57.5, 95.25, 57.5, -32.2000007629395, 95.25, 57.5, 0.0, 95.25, 0.0, -60.0, 90.0, 33.5999984741211, -60.0, 90.0, 60.0, -33.5999984741211, 90.0, 60.0, 0.0, 90.0], [80.0, 0.0, 30.0, 80.0, 44.7999992370605, 30.0, 44.7999992370605, 80.0, 30.0, 0.0, 80.0, 30.0, 80.0, 0.0, 12.0, 80.0, 44.7999992370605, 12.0, 44.7999992370605, 80.0, 12.0, 0.0, 80.0, 12.0, 60.0, 0.0, 3.0, 60.0, 33.5999984741211, 3.0, 33.5999984741211, 60.0, 3.0, 0.0, 60.0, 3.0, 60.0, 0.0, 0.0, 60.0, 33.5999984741211, 0.0, 33.5999984741211, 60.0, 0.0, 0.0, 60.0, 0.0], [0.0, 80.0, 30.0, -44.7999992370605, 80.0, 30.0, -80.0, 44.7999992370605, 30.0, -80.0, 0.0, 30.0, 0.0, 80.0, 12.0, -44.7999992370605, 80.0, 12.0, -80.0, 44.7999992370605, 12.0, -80.0, 0.0, 12.0, 0.0, 60.0, 3.0, -33.5999984741211, 60.0, 3.0, -60.0, 33.5999984741211, 3.0, -60.0, 0.0, 3.0, 0.0, 60.0, 0.0, -33.5999984741211, 60.0, 0.0, -60.0, 33.5999984741211, 0.0, -60.0, 0.0, 0.0], [60.0, 0.0, 90.0, 60.0, 33.5999984741211, 90.0, 33.5999984741211, 60.0, 90.0, 0.0, 60.0, 90.0, 70.0, 0.0, 69.0, 70.0, 39.2000007629395, 69.0, 39.2000007629395, 70.0, 69.0, 0.0, 70.0, 69.0, 80.0, 0.0, 48.0, 80.0, 44.7999992370605, 48.0, 44.7999992370605, 80.0, 48.0, 0.0, 80.0, 48.0, 80.0, 0.0, 30.0, 80.0, 44.7999992370605, 30.0, 44.7999992370605, 80.0, 30.0, 0.0, 80.0, 30.0], [0.0, 60.0, 90.0, -33.5999984741211, 60.0, 90.0, -60.0, 33.5999984741211, 90.0, -60.0, 0.0, 90.0, 0.0, 70.0, 69.0, -39.2000007629395, 70.0, 69.0, -70.0, 39.2000007629395, 69.0, -70.0, 0.0, 69.0, 0.0, 80.0, 48.0, -44.7999992370605, 80.0, 48.0, -80.0, 44.7999992370605, 48.0, -80.0, 0.0, 48.0, 0.0, 80.0, 30.0, -44.7999992370605, 80.0, 30.0, -80.0, 44.7999992370605, 30.0, -80.0, 0.0, 30.0], [56.0, 0.0, 90.0, 56.0, 31.3600006103516, 90.0, 31.3600006103516, 56.0, 90.0, 0.0, 56.0, 90.0, 53.5, 0.0, 95.25, 53.5, 29.9599990844727, 95.25, 29.9599990844727, 53.5, 95.25, 0.0, 53.5, 95.25, 57.5, 0.0, 95.25, 57.5, 32.2000007629395, 95.25, 32.2000007629395, 57.5, 95.25, 0.0, 57.5, 95.25, 60.0, 0.0, 90.0, 60.0, 33.5999984741211, 90.0, 33.5999984741211, 60.0, 90.0, 0.0, 60.0, 90.0], [0.0, 56.0, 90.0, -31.3600006103516, 56.0, 90.0, -56.0, 31.3600006103516, 90.0, -56.0, 0.0, 90.0, 0.0, 53.5, 95.25, -29.9599990844727, 53.5, 95.25, -53.5, 29.9599990844727, 95.25, -53.5, 0.0, 95.25, 0.0, 57.5, 95.25, -32.2000007629395, 57.5, 95.25, -57.5, 32.2000007629395, 95.25, -57.5, 0.0, 95.25, 0.0, 60.0, 90.0, -33.5999984741211, 60.0, 90.0, -60.0, 33.5999984741211, 90.0, -60.0, 0.0, 90.0], [-64.0, 0.0, 75.0, -64.0, 12.0, 75.0, -60.0, 12.0, 84.0, -60.0, 0.0, 84.0, -92.0, 0.0, 75.0, -92.0, 12.0, 75.0, -100.0, 12.0, 84.0, -100.0, 0.0, 84.0, -108.0, 0.0, 75.0, -108.0, 12.0, 75.0, -120.0, 12.0, 84.0, -120.0, 0.0, 84.0, -108.0, 0.0, 66.0, -108.0, 12.0, 66.0, -120.0, 12.0, 66.0, -120.0, 0.0, 66.0], [-60.0, 0.0, 84.0, -60.0, -12.0, 84.0, -64.0, -12.0, 75.0, -64.0, 0.0, 75.0, -100.0, 0.0, 84.0, -100.0, -12.0, 84.0, -92.0, -12.0, 75.0, -92.0, 0.0, 75.0, -120.0, 0.0, 84.0, -120.0, -12.0, 84.0, -108.0, -12.0, 75.0, -108.0, 0.0, 75.0, -120.0, 0.0, 66.0, -120.0, -12.0, 66.0, -108.0, -12.0, 66.0, -108.0, 0.0, 66.0], [-108.0, 0.0, 66.0, -108.0, 12.0, 66.0, -120.0, 12.0, 66.0, -120.0, 0.0, 66.0, -108.0, 0.0, 57.0, -108.0, 12.0, 57.0, -120.0, 12.0, 48.0, -120.0, 0.0, 48.0, -100.0, 0.0, 39.0, -100.0, 12.0, 39.0, -106.0, 12.0, 31.5, -106.0, 0.0, 31.5, -80.0, 0.0, 30.0, -80.0, 12.0, 30.0, -76.0, 12.0, 18.0, -76.0, 0.0, 18.0], [-120.0, 0.0, 66.0, -120.0, -12.0, 66.0, -108.0, -12.0, 66.0, -108.0, 0.0, 66.0, -120.0, 0.0, 48.0, -120.0, -12.0, 48.0, -108.0, -12.0, 57.0, -108.0, 0.0, 57.0, -106.0, 0.0, 31.5, -106.0, -12.0, 31.5, -100.0, -12.0, 39.0, -100.0, 0.0, 39.0, -76.0, 0.0, 18.0, -76.0, -12.0, 18.0, -80.0, -12.0, 30.0, -80.0, 0.0, 30.0], [68.0, 0.0, 51.0, 68.0, 26.3999996185303, 51.0, 68.0, 26.3999996185303, 18.0, 68.0, 0.0, 18.0, 104.0, 0.0, 51.0, 104.0, 26.3999996185303, 51.0, 124.0, 26.3999996185303, 27.0, 124.0, 0.0, 27.0, 92.0, 0.0, 78.0, 92.0, 10.0, 78.0, 96.0, 10.0, 75.0, 96.0, 0.0, 75.0, 108.0, 0.0, 90.0, 108.0, 10.0, 90.0, 132.0, 10.0, 90.0, 132.0, 0.0, 90.0], [68.0, 0.0, 18.0, 68.0, -26.3999996185303, 18.0, 68.0, -26.3999996185303, 51.0, 68.0, 0.0, 51.0, 124.0, 0.0, 27.0, 124.0, -26.3999996185303, 27.0, 104.0, -26.3999996185303, 51.0, 104.0, 0.0, 51.0, 96.0, 0.0, 75.0, 96.0, -10.0, 75.0, 92.0, -10.0, 78.0, 92.0, 0.0, 78.0, 132.0, 0.0, 90.0, 132.0, -10.0, 90.0, 108.0, -10.0, 90.0, 108.0, 0.0, 90.0], [108.0, 0.0, 90.0, 108.0, 10.0, 90.0, 132.0, 10.0, 90.0, 132.0, 0.0, 90.0, 112.0, 0.0, 93.0, 112.0, 10.0, 93.0, 141.0, 10.0, 93.75, 141.0, 0.0, 93.75, 116.0, 0.0, 93.0, 116.0, 6.0, 93.0, 138.0, 6.0, 94.5, 138.0, 0.0, 94.5, 112.0, 0.0, 90.0, 112.0, 6.0, 90.0, 128.0, 6.0, 90.0, 128.0, 0.0, 90.0], [132.0, 0.0, 90.0, 132.0, -10.0, 90.0, 108.0, -10.0, 90.0, 108.0, 0.0, 90.0, 141.0, 0.0, 93.75, 141.0, -10.0, 93.75, 112.0, -10.0, 93.0, 112.0, 0.0, 93.0, 138.0, 0.0, 94.5, 138.0, -6.0, 94.5, 116.0, -6.0, 93.0, 116.0, 0.0, 93.0, 128.0, 0.0, 90.0, 128.0, -6.0, 90.0, 112.0, -6.0, 90.0, 112.0, 0.0, 90.0], [50.0, 0.0, 90.0, 50.0, 28.0, 90.0, 28.0, 50.0, 90.0, 0.0, 50.0, 90.0, 52.0, 0.0, 90.0, 52.0, 29.1200008392334, 90.0, 29.1200008392334, 52.0, 90.0, 0.0, 52.0, 90.0, 54.0, 0.0, 90.0, 54.0, 30.2399997711182, 90.0, 30.2399997711182, 54.0, 90.0, 0.0, 54.0, 90.0, 56.0, 0.0, 90.0, 56.0, 31.3600006103516, 90.0, 31.3600006103516, 56.0, 90.0, 0.0, 56.0, 90.0], [0.0, 50.0, 90.0, -28.0, 50.0, 90.0, -50.0, 28.0, 90.0, -50.0, 0.0, 90.0, 0.0, 52.0, 90.0, -29.1200008392334, 52.0, 90.0, -52.0, 29.1200008392334, 90.0, -52.0, 0.0, 90.0, 0.0, 54.0, 90.0, -30.2399997711182, 54.0, 90.0, -54.0, 30.2399997711182, 90.0, -54.0, 0.0, 90.0, 0.0, 56.0, 90.0, -31.3600006103516, 56.0, 90.0, -56.0, 31.3600006103516, 90.0, -56.0, 0.0, 90.0], [-50.0, 0.0, 90.0, -50.0, -28.0, 90.0, -28.0, -50.0, 90.0, 0.0, -50.0, 90.0, -52.0, 0.0, 90.0, -52.0, -29.1200008392334, 90.0, -29.1200008392334, -52.0, 90.0, 0.0, -52.0, 90.0, -54.0, 0.0, 90.0, -54.0, -30.2399997711182, 90.0, -30.2399997711182, -54.0, 90.0, 0.0, -54.0, 90.0, -56.0, 0.0, 90.0, -56.0, -31.3600006103516, 90.0, -31.3600006103516, -56.0, 90.0, 0.0, -56.0, 90.0], [0.0, -50.0, 90.0, 28.0, -50.0, 90.0, 50.0, -28.0, 90.0, 50.0, 0.0, 90.0, 0.0, -52.0, 90.0, 29.1200008392334, -52.0, 90.0, 52.0, -29.1200008392334, 90.0, 52.0, 0.0, 90.0, 0.0, -54.0, 90.0, 30.2399997711182, -54.0, 90.0, 54.0, -30.2399997711182, 90.0, 54.0, 0.0, 90.0, 0.0, -56.0, 90.0, 31.3600006103516, -56.0, 90.0, 56.0, -31.3600006103516, 90.0, 56.0, 0.0, 90.0], [8.0, 0.0, 102.0, 8.0, 4.48000001907349, 102.0, 4.48000001907349, 8.0, 102.0, 0.0, 8.0, 102.0, 16.0, 0.0, 96.0, 16.0, 8.96000003814697, 96.0, 8.96000003814697, 16.0, 96.0, 0.0, 16.0, 96.0, 52.0, 0.0, 96.0, 52.0, 29.1200008392334, 96.0, 29.1200008392334, 52.0, 96.0, 0.0, 52.0, 96.0, 52.0, 0.0, 90.0, 52.0, 29.1200008392334, 90.0, 29.1200008392334, 52.0, 90.0, 0.0, 52.0, 90.0], [0.0, 8.0, 102.0, -4.48000001907349, 8.0, 102.0, -8.0, 4.48000001907349, 102.0, -8.0, 0.0, 102.0, 0.0, 16.0, 96.0, -8.96000003814697, 16.0, 96.0, -16.0, 8.96000003814697, 96.0, -16.0, 0.0, 96.0, 0.0, 52.0, 96.0, -29.1200008392334, 52.0, 96.0, -52.0, 29.1200008392334, 96.0, -52.0, 0.0, 96.0, 0.0, 52.0, 90.0, -29.1200008392334, 52.0, 90.0, -52.0, 29.1200008392334, 90.0, -52.0, 0.0, 90.0], [-8.0, 0.0, 102.0, -8.0, -4.48000001907349, 102.0, -4.48000001907349, -8.0, 102.0, 0.0, -8.0, 102.0, -16.0, 0.0, 96.0, -16.0, -8.96000003814697, 96.0, -8.96000003814697, -16.0, 96.0, 0.0, -16.0, 96.0, -52.0, 0.0, 96.0, -52.0, -29.1200008392334, 96.0, -29.1200008392334, -52.0, 96.0, 0.0, -52.0, 96.0, -52.0, 0.0, 90.0, -52.0, -29.1200008392334, 90.0, -29.1200008392334, -52.0, 90.0, 0.0, -52.0, 90.0], [0.0, -8.0, 102.0, 4.48000001907349, -8.0, 102.0, 8.0, -4.48000001907349, 102.0, 8.0, 0.0, 102.0, 0.0, -16.0, 96.0, 8.96000003814697, -16.0, 96.0, 16.0, -8.96000003814697, 96.0, 16.0, 0.0, 96.0, 0.0, -52.0, 96.0, 29.1200008392334, -52.0, 96.0, 52.0, -29.1200008392334, 96.0, 52.0, 0.0, 96.0, 0.0, -52.0, 90.0, 29.1200008392334, -52.0, 90.0, 52.0, -29.1200008392334, 90.0, 52.0, 0.0, 90.0], [0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 32.0, 0.0, 120.0, 32.0, 18.0, 120.0, 18.0, 32.0, 120.0, 0.0, 32.0, 120.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 8.0, 0.0, 102.0, 8.0, 4.48000001907349, 102.0, 4.48000001907349, 8.0, 102.0, 0.0, 8.0, 102.0], [0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 32.0, 120.0, -18.0, 32.0, 120.0, -32.0, 18.0, 120.0, -32.0, 0.0, 120.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 8.0, 102.0, -4.48000001907349, 8.0, 102.0, -8.0, 4.48000001907349, 102.0, -8.0, 0.0, 102.0], [0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, -32.0, 0.0, 120.0, -32.0, -18.0, 120.0, -18.0, -32.0, 120.0, 0.0, -32.0, 120.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, -8.0, 0.0, 102.0, -8.0, -4.48000001907349, 102.0, -4.48000001907349, -8.0, 102.0, 0.0, -8.0, 102.0], [0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, 0.0, 120.0, 0.0, -32.0, 120.0, 18.0, -32.0, 120.0, 32.0, -18.0, 120.0, 32.0, 0.0, 120.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, 0.0, 108.0, 0.0, -8.0, 102.0, 4.48000001907349, -8.0, 102.0, 8.0, -4.48000001907349, 102.0, 8.0, 0.0, 102.0]]
        }

        return PATCHES!
    }
}