//
//  MarqueeText.swift
//  sensor monkey
//
//  Created by Sitharaj Seenivasan on 16/07/25.
//

import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let startDelay: Double
    let speed: Double
    
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isAnimating = false
    
    init(
        text: String,
        font: Font = .body,
        color: Color = .primary,
        startDelay: Double = 1.0,
        speed: Double = 30.0
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.startDelay = startDelay
        self.speed = speed
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                    startMarqueeIfNeeded()
                                }
                                .onChange(of: text) { _, _ in
                                    textWidth = textGeometry.size.width
                                    containerWidth = geometry.size.width
                                    resetAndStartMarquee()
                                }
                        }
                    )
                
                // Duplicate text for seamless loop
                if textWidth > containerWidth {
                    Text(text)
                        .font(font)
                        .foregroundColor(color)
                        .lineLimit(1)
                        .padding(.leading, 20) // Gap between repeated text
                }
            }
            .offset(x: offset)
            .onAppear {
                containerWidth = geometry.size.width
                startMarqueeIfNeeded()
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                containerWidth = newWidth
                resetAndStartMarquee()
            }
        }
        .clipped()
    }
    
    private func startMarqueeIfNeeded() {
        guard textWidth > containerWidth else {
            offset = 0
            isAnimating = false
            return
        }
        
        guard !isAnimating else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
            startMarqueeAnimation()
        }
    }
    
    private func startMarqueeAnimation() {
        guard textWidth > containerWidth else { return }
        
        isAnimating = true
        let totalDistance = textWidth + 20 // Text width + gap
        let duration = totalDistance / speed
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -totalDistance
        }
    }
    
    private func resetAndStartMarquee() {
        withAnimation(.none) {
            offset = 0
            isAnimating = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startMarqueeIfNeeded()
        }
    }
}

// MARK: - Marquee Text with Auto-detect
struct AutoMarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let startDelay: Double
    let speed: Double
    
    @State private var needsMarquee = false
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    init(
        text: String,
        font: Font = .body,
        color: Color = .primary,
        startDelay: Double = 1.0,
        speed: Double = 30.0
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.startDelay = startDelay
        self.speed = speed
    }
    
    var body: some View {
        GeometryReader { geometry in
            if needsMarquee {
                MarqueeText(
                    text: text,
                    font: font,
                    color: color,
                    startDelay: startDelay,
                    speed: speed
                )
            } else {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(
            Text(text)
                .font(font)
                .lineLimit(1)
                .background(
                    GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                textWidth = textGeometry.size.width
                                containerWidth = textGeometry.size.width
                                updateMarqueeState(containerWidth: textGeometry.size.width)
                            }
                            .onChange(of: text) { _, _ in
                                textWidth = textGeometry.size.width
                                updateMarqueeState(containerWidth: containerWidth)
                            }
                    }
                )
                .opacity(0)
        )
        .onAppear {
            updateMarqueeState(containerWidth: containerWidth)
        }
    }
    
    private func updateMarqueeState(containerWidth: CGFloat) {
        needsMarquee = textWidth > containerWidth
    }
}
