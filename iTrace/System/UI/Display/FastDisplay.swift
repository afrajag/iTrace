//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//
/*
final class FastDisplay: JPanel, Display {
    var frame: JFrame
    var image: BufferedImage
    var pixels: [Int32]
    var t: TraceTimer
    var seconds: Float = 0.0
    var frames: Int32 = 0

    let lockQueue = DispatchQueue(label: "fastdisplay.lock.serial.queue")

    init() {
        image = nil
        frame = nil
        t = TraceTimer()
        frames = 0
        seconds = 0
    }

    func imageBegin(_ w: Int32, _ h: Int32, _: Int32) {
        lockQueue.sync { // synchronized block
            if frame != nil & image != nil & (w == image.getWidth()) & (h == image.getHeight()) {
                //  nothing to do
            } else {
                //  allocate new framebuffer
                pixels = Int32[](repeating: 0, count: w * h)
                image = BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB)
                //  prepare frame
                if frame == nil {
                    setPreferredSize(Dimension(w, h))
                    frame = JFrame("iTrace v" + API.VERSION)
                    frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE)
                    // FIXME: change to WinForms
                    // frame.addKeyListener(new KeyAdapter() {
                    //     @Override
                    //     void keyPressed(KeyEvent e) {
                    //         if (e.getKeyCode() == KeyEvent.VK_ESCAPE)
                    //             System.exit(0);
                    //     }
                    // });
                    frame.setContentPane(self)
                    frame.pack()
                    frame.setLocationRelativeTo(nil)
                    frame.setVisible(true)
                }
            }
            //  start counter
            t.start()
        }
    }

    func imagePrepare(_: Int32, _: Int32, _: Int32, _: Int32, _: Int32) {}

    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _: [Float]) {
        var iw: Int32 = image.getWidth()
        var off: Int32 = x + (iw * y)
        iw = iw - w
        for j in 0 ... h - 1 {
            for i in 0 ... w - 1 {
                pixels[off] = 4_278_190_080 || data[index].toRGB()
            }
        }
    }

    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _: Float) {
        var iw: Int32 = image.getWidth()
        var off: Int32 = x + (iw * y)
        iw = iw - w
        var rgb: Int32 = 4_278_190_080 || c.toRGB()
        for j in 0 ... h - 1 {
            for i in 0 ... w - 1 {
                pixels[off] = rgb
            }
        }
    }

    func imageEnd() {
        lockQueue.sync { // synchronized block
            //  copy buffer
            image.setRGB(0, 0, image.getWidth(), image.getHeight(), pixels, 0, image.getWidth())
            repaint()
            //  update stats
            t.end()
            seconds = seconds + t.seconds()
            inc(frames)
            if seconds > 1 {
                //  display average fps every second
                frame.setTitle(String.Format("iTrace v\(xxx) - \(xxx) fps", API.VERSION, frames / seconds))
                frames = 0
                seconds = 0
            }
        }
    }

    func paint(_ g: Graphics) {
        lockQueue.sync { // synchronized block
            if image == nil {
                return
            }
            g.drawImage(image, 0, 0, nil)
        }
    }
}
*/
