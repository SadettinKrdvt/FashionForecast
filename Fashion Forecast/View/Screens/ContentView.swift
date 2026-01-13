//
//  ContentView.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    
    // ViewModel: İş mantığını yöneten sınıf
    @StateObject private var viewModel = WeatherStyleViewModel()
    
    // UI State: Stil ekleme ekranının görünürlüğü
    @State private var isAddingStyle = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. KATMAN: Dinamik Arka Plan
            backgroundLayer
            
            // 2. KATMAN: Hava Durumu Efektleri
            weatherEffectsLayer
            
            // 3. KATMAN: Ana İçerik
            mainContentLayer
        }
        .onAppear {
            viewModel.requestLocation()
        }
        .sheet(isPresented: $isAddingStyle) {
            // Stil ekleme ekranı (Components.swift'ten gelir)
            AddStyleSheet(
                isPresented: $isAddingStyle,
                availableIcons: Constants.availableIcons
            ) { name, icon in
                viewModel.addNewStyle(name: name, icon: icon)
            }
        }
    }
}

// MARK: - Subviews & Layers
private extension ContentView {
    
    // Arka plan gradyanı
    var backgroundLayer: some View {
        LinearGradient(
            gradient: Gradient(colors: viewModel.displayWeather.type.getGradientColors(isNight: viewModel.displayWeather.isNight)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.0), value: viewModel.displayWeather.type)
    }
    
    // Yağmur, kar vb. efektler
    var weatherEffectsLayer: some View {
        WeatherEffectsView(
            type: viewModel.displayWeather.type,
            isNight: viewModel.displayWeather.isNight
        )
        .id(viewModel.displayWeather.date) // Tarih değiştiğinde animasyonu yenile
        .drawingGroup() // Performans için GPU (Metal) üzerinde render et
        .ignoresSafeArea()
    }
    
    // Ekrandaki arama çubuğu ve bilgi kartları
    var mainContentLayer: some View {
        VStack(spacing: 0) {
            // A. Arama Çubuğu (Components.swift)
            SearchBarView(viewModel: viewModel)
                .zIndex(10) // Açılır listenin diğer öğelerin üzerinde kalması için
            
            // B. Kaydırılabilir İçerik Alanı
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // B1. Hava Durumu Bilgisi (Components.swift)
                    WeatherInfoView(viewModel: viewModel)
                    
                    // B2. Kontrol Paneli (Components.swift)
                    ControlPanelView(viewModel: viewModel, isAddingStyle: $isAddingStyle)
                }
            }
        }
    }
}

// MARK: - Constants
private extension ContentView {
    enum Constants {
        static let availableIcons = [
            "star.fill", "heart.fill", "flame.fill", "bolt.fill",
            "leaf.fill", "hare.fill", "eyeglasses", "mustache.fill",
            "crown.fill", "briefcase.fill", "music.note", "airplane"
        ]
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
