//
//  HomeViews.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 1. ARAMA ÇUBUĞU
struct SearchBarView: View {
    @ObservedObject var viewModel: WeatherStyleViewModel
    @State private var citySearch: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isLocationPressed: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                // Konum Butonu
                Button(action: {
                    playHaptic(style: .medium)
                    triggerLocationUpdate()
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .scaleEffect(isLocationPressed ? 0.8 : 1.0)
                        .animation(.spring(), value: isLocationPressed)
                }
                .padding(.leading)
                
                // Arama Kutusu
                TextField("", text: $citySearch, prompt: Text("Şehir Ara... (örn: Ankara)").foregroundColor(.white.opacity(0.7)))
                    .onChange(of: citySearch) { _, newValue in
                        viewModel.searchCities(query: newValue)
                    }
                    .onSubmit {
                        playHaptic()
                        performSearch()
                    }
                    .focused($isSearchFocused)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                
                // Temizle Butonu
                if !citySearch.isEmpty {
                    Button(action: {
                        citySearch = ""
                        isSearchFocused = false
                        viewModel.searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 12)
                }
                
                // ARA Butonu
                Button(action: {
                    playHaptic()
                    performSearch()
                }) {
                    Text("ARA")
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.trailing)
            }
            
            // Arama Sonuçları Listesi
            if !viewModel.searchResults.isEmpty && isSearchFocused {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.searchResults, id: \.self) { completion in
                            Button(action: {
                                playHaptic()
                                citySearch = completion.title
                                viewModel.searchResults = []
                                isSearchFocused = false
                                viewModel.selectLocation(completion)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(completion.title).foregroundColor(.primary).font(.body.bold())
                                    Text(completion.subtitle).foregroundColor(.secondary).font(.caption)
                                }
                                .padding(.vertical, 10).padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .systemBackground))
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 25).padding(.top, 60)
            }
        }
    }
    
    private func triggerLocationUpdate() {
        isLocationPressed = true
        isSearchFocused = false
        citySearch = ""
        viewModel.searchResults = []
        viewModel.requestLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isLocationPressed = false }
    }
    
    private func performSearch() {
        isSearchFocused = false
        viewModel.searchResults = []
        viewModel.searchForCity(cityName: citySearch)
    }
}

// MARK: - 2. HAVA DURUMU KARTI
struct WeatherInfoView: View {
    @ObservedObject var viewModel: WeatherStyleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Gün Seçimi
            HStack(spacing: 0) {
                Button(action: {
                    playHaptic()
                    withAnimation { viewModel.toggleDay(showTomorrow: false) }
                }) {
                    Text("Bugün")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(viewModel.isShowingTomorrow ? Color.clear : Color.white.opacity(0.2))
                        .foregroundColor(.white)
                }
                Button(action: {
                    playHaptic()
                    withAnimation { viewModel.toggleDay(showTomorrow: true) }
                }) {
                    Text("Yarın")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(viewModel.isShowingTomorrow ? Color.white.opacity(0.2) : Color.clear)
                        .foregroundColor(.white)
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            // Ana Bilgiler
            VStack(spacing: 5) {
                Text(viewModel.cityName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white).shadow(radius: 2)
                
                Text(viewModel.getFormattedDate(date: viewModel.displayWeather.date))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8)).padding(.bottom, 5)
                
                HStack(alignment: .center, spacing: 15) {
                    Image(systemName: viewModel.displayWeather.type.getIconName(isNight: viewModel.displayWeather.isNight))
                        .renderingMode(.original).resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                    
                    Text("\(viewModel.displayWeather.temp)°")
                        .font(.system(size: 90, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 2) {
                    Text(viewModel.displayWeather.condition)
                        .font(.title3).fontWeight(.medium).foregroundColor(.white)
                    
                    if viewModel.displayWeather.temp != 0 {
                        Text("Hissedilen: \(viewModel.displayWeather.feelsLike)°")
                            .font(.subheadline).foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - 3. KONTROL PANELİ
struct ControlPanelView: View {
    @ObservedObject var viewModel: WeatherStyleViewModel
    @Binding var isAddingStyle: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            
            // Cinsiyet Seçimi
            VStack(alignment: .leading, spacing: 10) {
                Label("CİNSİYET", systemImage: "person.text.rectangle")
                    .font(.caption).fontWeight(.heavy).foregroundColor(.secondary)
                
                HStack(spacing: 0) {
                    ForEach(viewModel.genders, id: \.self) { gender in
                        Button(action: {
                            playHaptic()
                            withAnimation { viewModel.updateGender(to: gender) }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: gender == "Kadın" ? "person.fill" : "person")
                                Text(gender)
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(viewModel.selectedGender == gender ? Color.white : Color.white.opacity(0.25))
                            .foregroundColor(viewModel.selectedGender == gender ? .black : .secondary)
                            .cornerRadius(10)
                            .shadow(color: viewModel.selectedGender == gender ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
                        }
                    }
                }
                // GÜNCELLEME: Arka plan kutusu ve padding kaldırıldı
            }
            
            // Stil Seçimi
            VStack(alignment: .leading, spacing: 10) {
                Label("GİYİM TARZI", systemImage: "tshirt")
                    .font(.caption).fontWeight(.heavy).foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.styles) { style in
                            StyleButton(style: style, viewModel: viewModel)
                        }
                        
                        Button(action: {
                            playHaptic()
                            isAddingStyle = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Ekle")
                            }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color.white.opacity(0.5)).foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.vertical, 5).padding(.horizontal, 2)
                }
            }
            
            Divider()
            
            // AI Tavsiyesi
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        .font(.title2)
                    Text("Stilist Önerisi").font(.title3).bold().foregroundColor(.primary)
                    Spacer()
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Hazırlanıyor...").tint(.blue)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    // Metin sola yaslı, kutu tam genişlikte
                    Text(viewModel.advice)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.advice.contains("Hata") ? .red : .primary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            ZStack {
                                Rectangle().fill(.ultraThinMaterial)
                                LinearGradient(colors: viewModel.displayWeather.type.buttonGradient, startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.1)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: viewModel.displayWeather.type.buttonGradient, startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.3), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
            }
            
            Button(action: {
                playHaptic(style: .heavy)
                viewModel.fetchAIAdvice()
            }) {
                HStack {
                    Text("Kombini Hazırla").fontWeight(.bold)
                    Image(systemName: "wand.and.stars.inverse")
                }
                .font(.title3).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(LinearGradient(gradient: Gradient(colors: viewModel.displayWeather.type.buttonGradient), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(18)
                .shadow(color: viewModel.displayWeather.type.buttonGradient.first?.opacity(0.4) ?? .blue.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(35)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}

// Yardımcı Alt Görünüm: Stil Butonu
struct StyleButton: View {
    let style: StyleItem
    @ObservedObject var viewModel: WeatherStyleViewModel
    
    var body: some View {
        Button(action: {
            playHaptic()
            withAnimation { viewModel.updateStyle(to: style.name) }
        }) {
            HStack(spacing: 6) {
                Image(systemName: style.icon)
                Text(style.name)
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(
                viewModel.selectedStyle == style.name ?
                AnyView(LinearGradient(gradient: Gradient(colors: viewModel.displayWeather.type.buttonGradient), startPoint: .topLeading, endPoint: .bottomTrailing)) :
                    AnyView(Color.white.opacity(0.25))
            )
            .foregroundColor(viewModel.selectedStyle == style.name ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: viewModel.selectedStyle == style.name ? viewModel.displayWeather.type.buttonGradient.first?.opacity(0.4) ?? .gray.opacity(0.1) : .gray.opacity(0.1), radius: 5, x: 0, y: 3)
            .overlay(Capsule().stroke(Color.gray.opacity(0.1), lineWidth: viewModel.selectedStyle == style.name ? 0 : 1))
        }
        .onDrag {
            viewModel.currentDraggedStyle = style
            return NSItemProvider(object: style.name as NSString)
        }
        .onDrop(of: [UTType.text], delegate: StyleDropDelegate(item: style, viewModel: viewModel))
        .contextMenu {
            if style.isRemovable {
                Button(role: .destructive) {
                    playHaptic(style: .medium)
                    withAnimation { viewModel.removeStyle(item: style) }
                } label: { Label("Stili Sil", systemImage: "trash") }
            }
        }
    }
}
