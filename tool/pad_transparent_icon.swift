import AppKit

guard CommandLine.arguments.count == 5 else {
  fatalError("Usage: pad_transparent_icon <input> <output> <canvas-size> <art-size>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let canvasSize = Int(CommandLine.arguments[3])!
let artSize = Int(CommandLine.arguments[4])!

guard let source = NSImage(contentsOf: inputURL) else {
  fatalError("Unable to load input image")
}

guard let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: canvasSize,
  pixelsHigh: canvasSize,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fatalError("Unable to create output bitmap")
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
  fatalError("Unable to create graphics context")
}
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize).fill()

let origin = CGFloat(canvasSize - artSize) / 2
source.draw(
  in: NSRect(
    x: origin,
    y: origin,
    width: CGFloat(artSize),
    height: CGFloat(artSize)
  ),
  from: .zero,
  operation: .copy,
  fraction: 1
)
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
  fatalError("Unable to encode PNG")
}
try png.write(to: outputURL)
