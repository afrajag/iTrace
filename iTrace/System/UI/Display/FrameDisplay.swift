//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
/*
final class FrameDisplay: Display {
    var filename: String
    var frame: RenderFrame

    init() {
        self.init(nil)
    }

    init(_ filename: String) {
        self.filename = filename
        frame = nil
    }

    func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
        if frame == nil {
            frame = RenderFrame()
            frame.imagePanel.imageBegin(w, h, bucketSize)
            var screenRes: Dimension = Toolkit.getDefaultToolkit().getScreenSize()
            var needFit: Bool = false
            if (w >= (screenRes.getWidth() - 200)) | (h >= (screenRes.getHeight() - 200)) {
                frame.imagePanel.setPreferredSize(Dimension((screenRes.getWidth() as Int32) - 200, (screenRes.getHeight() as Int32) - 200))
                needFit = true
            } else {
                frame.imagePanel.setPreferredSize(Dimension(w, h))
            }
            frame.pack()
            frame.setLocationRelativeTo(nil)
            frame.setVisible(true)
            if needFit {
                frame.imagePanel.fit()
            }
        } else {
            frame.imagePanel.imageBegin(w, h, bucketSize)
        }
    }

    func imagePrepare(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ id: Int32) {
        frame.imagePanel.imagePrepare(x, y, w, h, id)
    }

    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _: Float[]) {
        frame.imagePanel.imageUpdate(x, y, w, h, data)
    }

    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _: Float) {
        frame.imagePanel.imageFill(x, y, w, h, c)
    }

    func imageEnd() {
        frame.imagePanel.imageEnd()
        if filename != nil {
            frame.imagePanel.save(filename)
        }
    }

    final class RenderFrame: JFrame {
        var imagePanel: ImagePanel

        init() {
            super.init("iTrace v" + API.VERSION)
            setDefaultCloseOperation(EXIT_ON_CLOSE)
            // addKeyListener(new KeyAdapter() {//fixme: change to WinForms
            //     @Override
            //     void keyPressed(KeyEvent e) {
            //         if (e.getKeyCode() == KeyEvent.VK_ESCAPE)
            //             System.exit(0);
            //     }
            // });
            imagePanel = ImagePanel()
            setContentPane(imagePanel)
            pack()
        }
    }
}
*/
