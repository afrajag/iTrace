//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

final class ImagePanel {
    // FIXME: implentare il lock (cambiare nome alla coda con il nome della classe)

    /*: JPanel, Display {
     static var BORDERS: [Int32] = [Color.RED.toRGB(), Color.GREEN.toRGB(), Color.BLUE.toRGB(), Color.YELLOW.toRGB(), Color.CYAN.toRGB(), Color.MAGENTA.toRGB()]
     var image: BufferedImage
     var repaintCounter: Int64 = 0
     var lockObj: Object = Object()
     var xo: Float = 0.0
     var yo: Float = 0.0
     var w: Float = 0.0
     var h: Float = 0.0

     init() {
     	setPreferredSize(Dimension(640, 480))
     	image = nil
     	xo = yo = 0
     	w = h = 0
     	var listener: ScrollZoomListener = ScrollZoomListener()
     	addMouseListener(listener)
     	addMouseMotionListener(listener)
     	addMouseWheelListener(listener)
     }

     func save(_ filename: String) {
     	Bitmap.save(image, filename)
     }

     func drag(_ dx: Int32, _ dy: Int32) {
     __lock; lockObj {
     	xo = xo + dx
     	yo = yo + dy
     	repaint()
     	}
     }

     func zoom(_ dx: Int32, _ dy: Int32) {
     __lock; lockObj {
     	var a: Int32 = max(dx, dy)
     	var b: Int32 = min(dx, dy)
     	if abs(b) > abs(a) {
     		a = b
     	}
     	if a == 0 {
     		return
     	}
     	//  window center
     	var cx: Float = getWidth() * 0.5
     	var cy: Float = getHeight() * 0.5
     	//  origin of the image in window space
     	var x: Float = xo + ((getWidth() - w) * 0.5)
     	var y: Float = yo + ((getHeight() - h) * 0.5)
     	//  coordinates of the pixel we are over
     	var sx: Float = cx - x
     	var sy: Float = cy - y
     	//  scale
     	if (w + a) > 100 {
     		h = ((w + a) * h) / w
     		sx = ((w + a) * sx) / w
     		sy = ((w + a) * sy) / w
     		w = w + a
     	}
     	//  restore center pixel
     	var x2: Float = cx - sx
     	var y2: Float = cy - sy
     	xo = x2 - ((getWidth() - w) * 0.5)
     	yo = y2 - ((getHeight() - h) * 0.5)
     	repaint()
     	}
     }

     func reset() {
     __lock; lockObj {
     	xo = yo = 0
     	if image != nil {
     		w = image.getWidth()
     		h = image.getHeight()
     	}
     	repaint()
     	}
     }

     func fit() {
     __lock; lockObj {
     	xo = yo = 0
     	if image != nil {
     		var wx: Float = max(getWidth() - 10, 100)
     		var hx: Float = (wx * image.getHeight()) / image.getWidth()
     		var hy: Float = max(getHeight() - 10, 100)
     		var wy: Float = (hy * image.getWidth()) / image.getHeight()
     		if hx > hy {
     			w = wy
     			h = hy
     		} else {
     			w = wx
     			h = hx
     		}
     		repaint()
     	}
     	}
     }

     func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
     __lock; lockObj {
     	if image != nil & (w == image.getWidth()) & (h == image.getHeight()) {
     		//  dull image if it has same resolution (75%)
     		for y in 0 ... h - 1 {
     			for x in 0 ... w - 1 {
     				var rgb: Int32 = image.getRGB(x, y)
     				image.setRGB(x, y, ((rgb && 16711422 as UInt32) >> 1) + ((rgb && 16579836 as UInt32) >> 2))
     				// >>>
     			}
     		}
     	} else {
     		//  allocate new framebuffer
     		image = BufferedImage(w, h, BufferedImage.TYPE_INT_RGB)
     		//  center
     		self.w = w
     		self.h = h
     		xo = yo = 0
     	}
     	repaintCounter = NanoTime.Now
     	repaint()
     	}
     }

     func imagePrepare(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ id: Int32) {
     __lock; lockObj {
     	var border: Int32 = BORDERS[id % BORDERS.count]
     	for by in 0 ... h - 1 {
     		for bx in 0 ... w - 1 {
     			if (bx == 0) | (bx == (w - 1)) {
     				if ((5 * by) < h) | ((5 * (h - by - 1)) < h) {
     					image.setRGB(x + bx, y + by, border)
     				}
     			} else {
     				if (by == 0) | (by == (h - 1)) {
     					if ((5 * bx) < w) | ((5 * (w - bx - 1)) < w) {
     						image.setRGB(x + bx, y + by, border)
     					}
     				}
     			}
     		}
     	}
     	repaint()
     	}
     }

     func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _ alpha: Float[]) {
     __lock; lockObj {
     	for j in 0 ... h - 1 {
     		for i in 0 ... w - 1 {
     			image.setRGB(x + i, y + j, data[index].copy().mul(1.0 / alpha[index]).toNonLinear().toRGBA(alpha[index]))
     		}
     	}
     	repaint()
     	}
     }

     func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _ alpha: Float) {
     __lock; lockObj {
     	var rgba: Int32 = c.copy().mul(1.0 / alpha).toNonLinear().toRGBA(alpha)
     	for j in 0 ... h - 1 {
     		for i in 0 ... w - 1 {
     			image.setRGB(x + i, y + j, rgba)
     		}
     	}
     	fastRepaint()
     	}
     }

     func imageEnd() {
     	repaint()
     }

     func fastRepaint() {
     	var t: Int64 = NanoTime.Now
     	if (repaintCounter + 125000000) < t {
     		repaintCounter = t
     		repaint()
     	}
     }

     override func paintComponent(_ g: Graphics) {
     __lock; lockObj {
     	super.paintComponent(g)
     	if image == nil {
     		return
     	}
     	var x: Int32 = Math.round(xo + ((getWidth() - w) * 0.5))
     	var y: Int32 = Math.round(yo + ((getHeight() - h) * 0.5))
     	var iw: Int32 = Math.round(w)
     	var ih: Int32 = Math.round(h)
     	var x0: Int32 = x - 1
     	var y0: Int32 = y - 1
     	var x1: Int32 = x + iw + 1
     	var y1: Int32 = y + ih + 1
     	g.setColor(java.awt.Color.WHITE)
     	g.drawLine(x0, y0, x1, y0)
     	g.drawLine(x1, y0, x1, y1)
     	g.drawLine(x1, y1, x0, y1)
     	g.drawLine(x0, y1, x0, y0)
     	g.drawImage(image, x, y, iw, ih, java.awt.Color.BLACK, self)
     	}
     }

     final class ScrollZoomListener : MouseInputAdapter, MouseWheelListener {
     	 var mx: Int32 = 0
     	 var my: Int32 = 0
     	 var dragging: Bool = false
     	 var zooming: Bool = false

     	func mousePressed(_ e: MouseEvent) {
     		mx = e.getX()
     		my = e.getY()
     		switch e.getButton() {
     			case MouseEvent.BUTTON1:
     				dragging = true
     				zooming = false
     			case MouseEvent.BUTTON2:
     do {
     dragging = zooming == false
     				//  if CTRL is pressed
     				if (e.getModifiersEx() && InputEvent.CTRL_DOWN_MASK) == InputEvent.CTRL_DOWN_MASK {
     					fit()
     				} else {
     					reset()
     				}
     				break
     			}
     			case MouseEvent.BUTTON3:
     				zooming = true
     				dragging = false
     			default:
     				return
     		}
     		repaint()
     	}

     	func mouseDragged(_ e: MouseEvent) {
     		var mx2: Int32 = e.getX()
     		var my2: Int32 = e.getY()
     		if dragging {
     			drag(mx2 - mx, my2 - my)
     		}
     		if zooming {
     			zoom(mx2 - mx, my2 - my)
     		}
     		mx = mx2
     		my = my2
     	}

     	func mouseReleased(_ e: MouseEvent) {
     		//  same behaviour
     		mouseDragged(e)
     	}

     	func mouseWheelMoved(_ e: MouseWheelEvent) {
     		zoom(-20 * e.getWheelRotation(), 0)
     	}
     } */
}
