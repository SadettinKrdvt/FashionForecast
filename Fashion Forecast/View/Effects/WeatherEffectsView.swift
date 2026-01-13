//
//  WeatherEffectsView.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import SwiftUI

// MARK: - ANA EFEKT GÖRÜNÜMÜ
struct WeatherEffectsView: View {
    let type: WeatherType
    let isNight: Bool
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // 1. Güneş / Ay (Açık ve Soğuk havalar için)
                if !isNight && (type == .sunny || type == .clearCold) {
                    SunView(size: proxy.size)
                }

                // 2. Yıldızlar (Gece; açık veya az bulutlu)
                if isNight && (type == .sunny || type == .clearCold || type == .cloudy) {
                    StarView(size: proxy.size)
                }
                
                // 3. Sis
                if type == .fog {
                    FogView(size: proxy.size)
                }
                
                // 4. Yağmur ve Fırtına
                if type == .rainy || type == .drizzle || type == .thunderstorm {
                    RainView(size: proxy.size, isStorm: type == .thunderstorm)
                }
                
                // 5. Kar
                if type == .snowy {
                    SnowView(size: proxy.size)
                }
                
                // 6. Bulutlar (Birçok durumda görünür)
                if type == .cloudy || type == .rainy || type == .thunderstorm || type == .drizzle {
                    CloudView(size: proxy.size, isNight: isNight)
                }
            }
        }
        .allowsHitTesting(false) // Kullanıcı etkileşimini engelle (arkaya tıklanabilsin)
    }
}

// MARK: - 1. Güneş Efekti
struct SunView: View {
    let size: CGSize
    @State private var offset: CGFloat = -150
    
    private let animationDuration: Double = 60.0
    
    var body: some View {
        ZStack {
            // Dış Hare (Glow)
            Image(systemName: "sun.max.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 160)
                .foregroundColor(.orange.opacity(0.4))
                .blur(radius: 20)
                .offset(x: offset, y: 50)
            
            // İç Güneş
            Image(systemName: "sun.max.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .foregroundColor(.yellow.opacity(0.9))
                .shadow(color: .orange.opacity(0.6), radius: 30, x: 0, y: 0)
                .blur(radius: 2)
                .offset(x: offset, y: 50)
        }
        .onAppear {
            // Güneşin ekran boyunca yavaşça kayması
            withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                offset = size.width + 150
            }
        }
    }
}

// MARK: - 2. Yağmur Efekti
struct RainView: View {
    let size: CGSize
    let isStorm: Bool
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let dropsCount = isStorm ? 400 : 200 // Fırtınada daha yoğun yağmur
                
                for i in 0..<dropsCount {
                    // Rastgele ama tutarlı pozisyonlar üretmek için matematiksel hileler
                    let randomX = Double((i * 1357) % Int(size.width))
                    let randomYStart = Double((i * 8191) % Int(size.height))
                    let speed = Double(300 + (i * 17 % 200))
                    
                    var y = (time * speed + randomYStart).remainder(dividingBy: size.height)
                    if y < 0 { y += size.height }
                    
                    let width: Double = 2
                    let height: Double = isStorm ? 20 : 15
                    
                    let rect = CGRect(x: randomX, y: y, width: width, height: height)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: width/2, height: width/2))
                    
                    context.fill(path, with: .color(.white.opacity(0.4)))
                }
            }
        }
    }
}

// MARK: - 3. Kar Efekti
struct SnowView: View {
    let size: CGSize
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let flakesCount = 150
                
                for i in 0..<flakesCount {
                    let randomX = Double(i * 997 % Int(size.width))
                    let randomYStart = Double((i * 6997) % Int(size.height))
                    
                    // Sağa sola salınım hareketi
                    let sway = sin(time + Double(i)) * 10
                    let speed = Double(40 + (i * 5 % 60))
                    
                    let totalHeight = size.height + 20
                    var y = (time * speed + randomYStart).remainder(dividingBy: totalHeight)
                    if y < 0 { y += totalHeight }
                    
                    let x = randomX + sway
                    let flakeSize = Double(2 + (i % 5))
                    
                    let rect = CGRect(x: x, y: y, width: flakeSize, height: flakeSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.7)))
                }
            }
        }
    }
}

// MARK: - 4. Sis Efekti
struct FogView: View {
    let size: CGSize
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Katman 1
            Rectangle()
                .fill(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: size.width * 2, height: size.height)
                .offset(x: offset1)
                .blur(radius: 20)
            
            // Katman 2 (Ters yönde)
            Rectangle()
                .fill(LinearGradient(colors: [.gray.opacity(0.2), .clear], startPoint: .trailing, endPoint: .leading))
                .frame(width: size.width * 2, height: size.height)
                .offset(x: offset2)
                .blur(radius: 30)
        }
        .onAppear {
            // Sonsuz döngü animasyonlar
            offset1 = -size.width
            offset2 = size.width
            
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: true)) {
                offset1 = 0
            }
            withAnimation(.linear(duration: 50).repeatForever(autoreverses: true)) {
                offset2 = 0
            }
        }
    }
}

// MARK: - 5. Bulut Efekti
struct CloudView: View {
    let size: CGSize
    let isNight: Bool
    
    @State private var offset1: CGFloat = -200
    @State private var offset2: CGFloat = -300
    
    var body: some View {
        ZStack {
            // Bulut 1
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 220)
                .foregroundColor(isNight ? .gray.opacity(0.4) : .white.opacity(0.5))
                .offset(x: offset1, y: 20)
                .blur(radius: 5)
            
            // Bulut 2
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180)
                .foregroundColor(isNight ? .gray.opacity(0.3) : .white.opacity(0.4))
                .offset(x: offset2, y: 70)
                .blur(radius: 8)
        }
        .onAppear {
            // Ekranı boydan boya geçip başa saran animasyon
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                offset1 = size.width + 100
            }
            withAnimation(.linear(duration: 35).repeatForever(autoreverses: false)) {
                offset2 = size.width + 100
            }
        }
    }
}

// MARK: - 6. Yıldız Efekti
struct StarView: View {
    let size: CGSize
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<50 {
                    // Rastgele ama sabit (deterministic) pozisyonlar
                    let randomXRatio = Double((i * 911 + 7) % 1000) / 1000.0
                    let randomYRatio = Double((i * 733 + 3) % 500) / 1000.0
                    
                    let randomX = randomXRatio * size.width
                    let randomY = randomYRatio * size.height
                    
                    // Yanıp sönme efekti (Twinkle)
                    let opacity = (sin(time * 1.5 + Double(i)) + 1) / 2 * 0.7 + 0.3
                    
                    let rect = CGRect(x: randomX, y: randomY, width: 2.5, height: 2.5)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
                }
            }
        }
    }
}
