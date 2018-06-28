//
// MARK: CGPoint op point/size/float
//

func -(l: CGPoint, r: CGPoint) -> CGPoint { return CGPoint(x: l.x - r.x, y: l.y - r.y) }
func +(l: CGPoint, r: CGPoint) -> CGPoint { return CGPoint(x: l.x + r.x, y: l.y + r.y) }
func *(l: CGPoint, r: CGPoint) -> CGPoint { return CGPoint(x: l.x * r.x, y: l.y * r.y) }
func /(l: CGPoint, r: CGPoint) -> CGPoint { return CGPoint(x: l.x / r.x, y: l.y / r.y) }

func -(l: CGPoint, r: CGSize) -> CGPoint { return CGPoint(x: l.x - r.width, y: l.y - r.height) }
func +(l: CGPoint, r: CGSize) -> CGPoint { return CGPoint(x: l.x + r.width, y: l.y + r.height) }
func *(l: CGPoint, r: CGSize) -> CGPoint { return CGPoint(x: l.x * r.width, y: l.y * r.height) }
func /(l: CGPoint, r: CGSize) -> CGPoint { return CGPoint(x: l.x / r.width, y: l.y / r.height) }

func -(l: CGPoint, r: CGFloat) -> CGPoint { return CGPoint(x: l.x - r, y: l.y - r) }
func +(l: CGPoint, r: CGFloat) -> CGPoint { return CGPoint(x: l.x + r, y: l.y + r) }
func *(l: CGPoint, r: CGFloat) -> CGPoint { return CGPoint(x: l.x * r, y: l.y * r) }
func /(l: CGPoint, r: CGFloat) -> CGPoint { return CGPoint(x: l.x / r, y: l.y / r) }

func -=( l: inout CGPoint, r: CGPoint) { l = l - r }
func +=( l: inout CGPoint, r: CGPoint) { l = l + r }
func *=( l: inout CGPoint, r: CGPoint) { l = l * r }
func /=( l: inout CGPoint, r: CGPoint) { l = l / r }

func -=( l: inout CGPoint, r: CGSize) { l = l - r }
func +=( l: inout CGPoint, r: CGSize) { l = l + r }
func *=( l: inout CGPoint, r: CGSize) { l = l * r }
func /=( l: inout CGPoint, r: CGSize) { l = l / r }

func -=( l: inout CGPoint, r: CGFloat) { l = l - r }
func +=( l: inout CGPoint, r: CGFloat) { l = l + r }
func *=( l: inout CGPoint, r: CGFloat) { l = l * r }
func /=( l: inout CGPoint, r: CGFloat) { l = l / r }

extension CGPoint {
    init(x: CGFloat) {
        self.init()
        self.x = x
        self.y = 0
    }
    init(y: CGFloat) {
        self.init()
        self.x = 0
        self.y = y
    }

    func ceil() -> CGPoint {
        return CGPoint(x: CoreGraphics.ceil(x), y: CoreGraphics.ceil(y))
    }
    func floor() -> CGPoint {
        return CGPoint(x: CoreGraphics.floor(x), y: CoreGraphics.floor(y))
    }
    func round() -> CGPoint {
        return CGPoint(x: CoreGraphics.round(x), y: CoreGraphics.round(y))
    }
    func size() -> CGSize {
        return CGSize(width: x, height: y)
    }
    func toInts() -> (x: Int, y: Int) {
        return (x: Int(x), y: Int(y))
    }
    func len() -> CGFloat {
        let len_sqr = self.x * self.x + self.y * self.y
        return sqrt(len_sqr)
    }
    func norm() -> CGPoint {
        return CGPoint(x: -self.y, y: self.x)
    }
    
    func len(to p: CGPoint) -> CGFloat {
        let dx = p.x - self.x
        let dy = p.y - self.y
        let len_sqr = dx * dx + dy * dy
        return max(sqrt(len_sqr), 0.0001)
    }
    func unit(to p: CGPoint) -> CGPoint {
        
        let dx = p.x - self.x
        let dy = p.y - self.y
        let len = self.len(to: p)
        return CGPoint(x: dx / len, y: dy / len)
    }
    
    func middle(to p: CGPoint) -> CGPoint {
        let mx = (self.x + p.x)/2.0
        let my = (self.y + p.y)/2.0
        return CGPoint(x: mx, y: my)
    }
}

//
// MARK: CGSize op size/float
//

func -(l: CGSize, r: CGSize) -> CGSize { return CGSize(width: l.width - r.width, height: l.height - r.height) }
func +(l: CGSize, r: CGSize) -> CGSize { return CGSize(width: l.width + r.width, height: l.height + r.height) }
func *(l: CGSize, r: CGSize) -> CGSize { return CGSize(width: l.width * r.width, height: l.height * r.height) }
func /(l: CGSize, r: CGSize) -> CGSize { return CGSize(width: l.width / r.width, height: l.height / r.height) }

func -(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width - r, height: l.height - r) }
func +(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width + r, height: l.height + r) }
func *(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width * r, height: l.height * r) }
func /(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width / r, height: l.height / r) }

func -=( l: inout CGSize, r: CGSize) { l = l - r }
func +=( l: inout CGSize, r: CGSize) { l = l + r }
func *=( l: inout CGSize, r: CGSize) { l = l * r }
func /=( l: inout CGSize, r: CGSize) { l = l / r }

func -=( l: inout CGSize, r: CGFloat) { l = l - r }
func +=( l: inout CGSize, r: CGFloat) { l = l + r }
func *=( l: inout CGSize, r: CGFloat) { l = l * r }
func /=( l: inout CGSize, r: CGFloat) { l = l / r }

extension CGSize {
    init(width: CGFloat) {
        self.init()
        self.width = width
        self.height = 0
    }
    init(height: CGFloat) {
        self.init()
        self.width = 0
        self.height = height
    }

    func ceil()  -> CGSize { return CGSize(width: CoreGraphics.ceil(width),  height: CoreGraphics.ceil(height))  }
    func floor() -> CGSize { return CGSize(width: CoreGraphics.floor(width), height: CoreGraphics.floor(height)) }
    func round() -> CGSize { return CGSize(width: CoreGraphics.round(width), height: CoreGraphics.round(height)) }
    func point() -> CGPoint {
        return CGPoint(x: width, y: height)
    }
    func toInts() -> (width: Int, height: Int) {
        return (width: Int(width), height: Int(height))
    }
}

//
// MARK: CGRect accessors
//

extension CGRect {
    init(origin: CGPoint) {
        self.init()
        self.origin = origin
        self.size = CGSize()
    }
    init(size: CGSize) {
        self.init()
        self.origin = CGPoint()
        self.size = size
    }
    init(x: CGFloat, y: CGFloat) {
        self.init()
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize()
    }
    init(x: CGFloat, y: CGFloat, size: CGSize) {
        self.init()
        self.origin = CGPoint(x: x, y: y)
        self.size = size
    }
    init(width: CGFloat, height: CGFloat) {
        self.init()
        self.origin = CGPoint()
        self.size = CGSize(width: width, height: height)
    }
    init(origin: CGPoint, width: CGFloat, height: CGFloat) {
        self.init()
        self.origin = origin
        self.size = CGSize(width: width, height: height)
    }

    var x: CGFloat {
        get { return origin.x }
        set { origin.x = newValue }
    }
    var y: CGFloat {
        get { return origin.y }
        set { origin.y = newValue }
    }
    var width: CGFloat {
        get { return size.width }
        set { size.width = newValue }
    }
    var height: CGFloat {
        get { return size.height }
        set { size.height = newValue }
    }
    var centerX: CGFloat {
        get { return x + width / 2 }
        set { x = newValue - width / 2 }
    }
    var centerY: CGFloat {
        get { return y + height / 2 }
        set { y = newValue - height / 2 }
    }
    var center: CGPoint {
        get { return CGPoint(x: centerX, y: centerY) }
        set {
            centerX = newValue.x
            centerY = newValue.y
        }
    }
    var left: CGFloat {
        get { return x }
        set { x = newValue }
    }
    var top: CGFloat {
        get { return y }
        set { y = newValue }
    }
    var right: CGFloat {
        get { return x + width }
        set { x = newValue - width }
    }
    var bottom: CGFloat {
        get { return y + height }
        set { y = newValue - height }
    }
}


