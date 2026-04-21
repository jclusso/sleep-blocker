#!/usr/bin/env swift
import AppKit
import Foundation

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let size: CGFloat = 1024

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: size, height: size)
let rounded = NSBezierPath(roundedRect: rect, xRadius: 180, yRadius: 180)

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.30, alpha: 1),
    NSColor(calibratedRed: 0.30, green: 0.18, blue: 0.55, alpha: 1),
])!
gradient.draw(in: rounded, angle: 270)

let symbolPointSize: CGFloat = 700
let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
if let base = NSImage(systemSymbolName: "moon.zzz.fill", accessibilityDescription: nil),
   let moon = base.withSymbolConfiguration(config) {
    let glowColor = NSColor(calibratedRed: 1, green: 0.95, blue: 0.7, alpha: 0.35)
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 40
    shadow.shadowColor = glowColor
    shadow.shadowOffset = .zero
    shadow.set()

    let tinted = NSImage(size: moon.size)
    tinted.lockFocus()
    moon.draw(at: .zero, from: NSRect(origin: .zero, size: moon.size), operation: .sourceOver, fraction: 1)
    NSColor(calibratedRed: 1, green: 0.95, blue: 0.75, alpha: 1).set()
    let bounds = NSRect(origin: .zero, size: moon.size)
    bounds.fill(using: .sourceIn)
    tinted.unlockFocus()

    let drawSize = tinted.size
    let origin = NSPoint(x: (size - drawSize.width) / 2, y: (size - drawSize.height) / 2 - 10)
    tinted.draw(at: origin, from: NSRect(origin: .zero, size: drawSize), operation: .sourceOver, fraction: 1)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Failed to encode PNG\n".utf8))
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
