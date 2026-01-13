//
//  WeatherStyleViewModel.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

@MainActor
class WeatherStyleViewModel: NSObject, ObservableObject, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate {
    
    // MARK: - Dependencies
    private let weatherService = WeatherService()
    private let geminiService = GeminiService()
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    
    // MARK: - Internal State
    // API'den gelen ismin, bizim bulduğumuz doğru ismi ezmesini engellemek için saklıyoruz.
    private var geocodedCityName: String?
    
    // MARK: - Published Properties
    @Published var todayWeather: WeatherScenario?
    @Published var tomorrowWeather: WeatherScenario?
    @Published var displayWeather: WeatherScenario = WeatherScenario(temp: 0, condition: "Yükleniyor...", type: .cloudy, isNight: false, feelsLike: 0, date: Date())
    
    @Published var cityName: String = "Konum Bekleniyor..."
    @Published var selectedStyle: String = "Casual"
    @Published var selectedGender: String = "Kadın"
    @Published var advice: String = "Stilistiniz hazır. Hemen bir kombin oluşturun!"
    @Published var isLoading: Bool = false
    
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isShowingTomorrow: Bool = false
    @Published var styles: [StyleItem] = []
    @Published var currentDraggedStyle: StyleItem?
    
    let genders = ["Kadın", "Erkek"]
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadStyles()
        setupLocationManager()
        setupSearchCompleter()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        // İlçe tespiti için HundredMeters yeterli ve hızlıdır.
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    // MARK: - Style Management
    func loadStyles() {
        if let savedData = UserDefaults.standard.data(forKey: "UserStylesData"),
           let savedStyles = try? JSONDecoder().decode([StyleItem].self, from: savedData) {
            self.styles = savedStyles
        } else {
            self.styles = [
                StyleItem(name: "Casual", icon: "figure.walk", isRemovable: false),
                StyleItem(name: "Spor", icon: "figure.run", isRemovable: false),
                StyleItem(name: "Klasik", icon: "crown", isRemovable: false),
                StyleItem(name: "Business", icon: "briefcase", isRemovable: false)
            ]
        }
    }
    
    func addNewStyle(name: String, icon: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        if !styles.contains(where: { $0.name == cleanName }) {
            let newStyle = StyleItem(name: cleanName, icon: icon, isRemovable: true)
            styles.append(newStyle)
            saveStyles()
            updateStyle(to: cleanName)
        }
    }
    
    func removeStyle(item: StyleItem) {
        if let index = styles.firstIndex(of: item) {
            styles.remove(at: index)
            saveStyles()
        }
    }
    
    func saveStyles() {
        if let encoded = try? JSONEncoder().encode(styles) {
            UserDefaults.standard.set(encoded, forKey: "UserStylesData")
        }
    }
    
    func updateStyle(to newStyle: String) { selectedStyle = newStyle }
    func updateGender(to newGender: String) { selectedGender = newGender }
    
    // MARK: - Weather Data Fetching
    func loadWeather(for city: String? = nil, lat: Double? = nil, lon: Double? = nil) async {
        do {
            let weatherResponse: WeatherResponse
            let forecastResponse: ForecastResponse
            
            if let lat = lat, let lon = lon {
                weatherResponse = try await weatherService.fetchCurrentWeather(lat: lat, lon: lon)
                forecastResponse = try await weatherService.fetchForecast(lat: lat, lon: lon)
            } else if let city = city {
                weatherResponse = try await weatherService.fetchCurrentWeather(city: city)
                forecastResponse = try await weatherService.fetchForecast(city: city)
            } else {
                return
            }
            
            processWeatherData(current: weatherResponse, forecast: forecastResponse, cityNameOverride: city)
            
        } catch {
            print("Weather Fetch Error: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .invalidURL, .invalidResponse, .decodingError:
                self.advice = "Bağlantı hatası oluştu. Lütfen tekrar deneyin."
            case .apiError(let msg):
                self.advice = "Hata: \(msg)"
            }
        } else {
            if self.cityName == "Konum Bekleniyor..." || self.cityName == "İzin Gerekli" {
                self.advice = "Hava durumu alınamadı. Lütfen arama yapın veya internet bağlantınızı kontrol edin."
            }
        }
    }
    
    private func processWeatherData(current: WeatherResponse, forecast: ForecastResponse, cityNameOverride: String?) {
        let today = createScenario(from: current)
        self.todayWeather = today
        
        // İSİM BELİRLEME MANTIĞI (ÖNEMLİ):
        // 1. Önce manuel Override var mı? (Aramadan gelen)
        // 2. Yoksa, önceden bulduğumuz 'geocodedCityName' (Pendik) var mı?
        // 3. O da yoksa API'den gelen ismi kullan (İçmeler).
        // Bu sıralama sayesinde API'den gelen "İçmeler" ismi, bizim bulduğumuz "Pendik" ismini asla ezemez.
        
        var nameToDisplay = current.name // Varsayılan API ismi
        
        if let overrideName = cityNameOverride {
            nameToDisplay = overrideName
        } else if let geoName = self.geocodedCityName {
            nameToDisplay = geoName
        }
        
        // Temizleme işlemi
        self.cityName = nameToDisplay.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? nameToDisplay
        
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let noonComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrowDate)
        
        if let tomorrowItem = forecast.list.first(where: { item in
            let date = Date(timeIntervalSince1970: item.dt)
            let itemComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
            return itemComponents.day == noonComponents.day && (itemComponents.hour ?? 0) >= 11
        }) {
            self.tomorrowWeather = createForecastScenario(from: tomorrowItem)
        }
        
        updateDisplayWeather()
        self.advice = "Hava durumu güncellendi. Kombin önerisi alabilirsiniz."
    }
    
    func updateDisplayWeather() {
        if isShowingTomorrow, let tomorrow = tomorrowWeather {
            displayWeather = tomorrow
            advice = "Yarın için tavsiye almaya hazır."
        } else if let today = todayWeather {
            displayWeather = today
            advice = "Bugün için tavsiye almaya hazır."
        }
    }
    
    func toggleDay(showTomorrow: Bool) {
        isShowingTomorrow = showTomorrow
        updateDisplayWeather()
    }
    
    // MARK: - Location & Search
    func requestLocation() {
        // Yeni bir konum isteği başladığında eski cache'i temizle
        self.geocodedCityName = nil
        
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            self.cityName = "İzin Gerekli"
            self.advice = "⚠️ Konum izni reddedildi. Ayarlar'dan izni açmalısınız."
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.cityName = "İzin Gerekli"
                self.advice = "Konum izni verilmedi. Şehir arayabilir veya Ayarlar'dan izni açabilirsiniz."
            default: break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. ADIM: Hava durumunu HEMEN çek (Kullanıcı bekletilmez)
        Task { @MainActor in
            manager.stopUpdatingLocation()
            await loadWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
        
        // 2. ADIM: Doğru ismi (İlçe) bul ve kaydet
        Task {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let place = placemarks.first {
                    // İSİM FİLTRESİ:
                    // subAdministrativeArea = İlçe (Pendik) -> EN İYİSİ
                    // administrativeArea = İl (İstanbul) -> YEDEK
                    // locality ve subLocality (İçmeler, Kurtköy) -> YASAKLI
                    let districtName = place.subAdministrativeArea ?? place.administrativeArea
                    
                    if let finalName = districtName {
                        await MainActor.run {
                            // 1. İsmi hafızaya kaydet (böylece API bunu ezemez)
                            self.geocodedCityName = finalName
                            // 2. Ekranda hemen göster
                            self.cityName = finalName
                        }
                    }
                }
            } catch {
                print("Geocoder hatası: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location Error: \(error.localizedDescription)")
            if self.cityName == "Konum Bekleniyor..." {
                self.advice = "Konum bulunamadı. Lütfen tekrar deneyin."
            }
        }
    }
    
    func searchCities(query: String) {
        // Arama yaparken konum cache'ini temizle ki aranan şehrin ismi görünsün
        self.geocodedCityName = nil
        if query.isEmpty { searchResults = [] } else { searchCompleter.queryFragment = query }
    }
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            searchResults = completer.results.filter { !$0.title.isEmpty }
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Search Error: \(error.localizedDescription)")
        }
    }
    
    func selectLocation(_ completion: MKLocalSearchCompletion) {
        locationManager.stopUpdatingLocation()
        // Aramadan seçim yapıldığında da cache'i temizle
        self.geocodedCityName = nil
        
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, _ in
            guard let self = self, let item = response?.mapItems.first else { return }
            Task {
                await self.loadWeather(lat: item.placemark.coordinate.latitude, lon: item.placemark.coordinate.longitude)
                let shortName = completion.title.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? completion.title
                self.cityName = shortName
            }
        }
    }
    
    func searchForCity(cityName: String) {
        locationManager.stopUpdatingLocation()
        self.geocodedCityName = nil
        Task {
            await loadWeather(for: cityName)
        }
    }

    // MARK: - AI Advice
    func fetchAIAdvice() {
        isLoading = true
        advice = "Stilistiniz kombinleri hazırlıyor..."
        
        let dayLabel = isShowingTomorrow ? "YARIN" : "BUGÜN"
        let timeOfDay = displayWeather.isNight ? "Gece" : "Gündüz"
        
        let prompt = """
        Sen profesyonel bir kişisel stil danışmanısın.
        
        DURUM ANALİZİ:
        - Şehir: \(cityName)
        - Mevcut Sıcaklık: \(displayWeather.temp)°C
        - Hissedilen Sıcaklık: \(displayWeather.feelsLike)°C
        - Durum: \(displayWeather.condition)
        - Vakit: \(timeOfDay)
        
        KULLANICI PROFİLİ:
        - Cinsiyet: \(selectedGender)
        - Tercih Edilen Stil: \(selectedStyle)
        
        GÖREVİN:
        Kullanıcının dolabındaki her parçayı bilmediğimiz için, spesifik bir ürün dayatmak yerine o hava koşullarına uygun **basit ve genel kategoriler** öner.
        Bu önerinin \(dayLabel) için olduğunu unutma.
        
        KRİTİK KURALLAR:
        1. ÇOK BASİT VE HALK DİLİ KULLAN: "Kanvas", "Chino", "Merino", "Kaşmir", "Trenchkot", "Blazer", "Loafer" gibi anlaşılması zor moda terimlerini ASLA kullanma.
        2. YERİNE BUNLARI KULLAN: "Kumaş pantolon", "Kot pantolon", "Kalın kazak", "Uzun mont", "Spor ayakkabı", "Bot" gibi herkesin bildiği kelimeler seç.
        3. KATMANLAMA: "Tişört üstüne hırka" gibi pratik çözümler sun.
        4. KISA VE NET: Her madde çok kısa olsun, uzun uzun açıklama yapma.
        5. Formatı KESİNLİKLE bozma.
        
        CEVAP FORMATI:
        
        ÜST GİYİM:
        • [Kısa Parça Tanımı] (Örn: Pamuklu tişört)
        • [Varsa İkinci Katman] (Örn: Fermuarlı hırka)
        • [Genel Renk Önerisi]
        
        DIŞ GİYİM:
        (Hava sıcaksa "Gerek yok" yaz)
        • [Kısa Parça Tanımı] (Örn: Su geçirmeyen mont)
        
        ALT GİYİM:
        • [Kısa Parça Tanımı] (Örn: Kot pantolon veya Eşofman altı)
        • [Genel Renk Önerisi]
        
        AYAKKABI:
        • [Kısa Parça Tanımı] (Örn: Rahat spor ayakkabı veya Bot)
        
        AKSESUAR:
        • [Kısa Parça Tanımı] (Örn: Şemsiye veya Atkı)
        
        Sadece listeyi ver.
        """
        
        Task {
            do {
                let response = try await geminiService.generateAdvice(prompt: prompt)
                self.advice = response
            } catch {
                if let serviceError = error as? ServiceError {
                    self.advice = serviceError.errorDescription ?? "Hata oluştu."
                } else {
                    self.advice = "Tavsiye alınırken bir hata oluştu."
                }
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Helpers
    private func createScenario(from response: WeatherResponse) -> WeatherScenario {
        let weatherInfo = prioritizeWeather(response.weather)
        let type = mapWeatherType(id: weatherInfo?.id ?? 800, temp: response.main.temp)
        let isNight = weatherInfo?.icon.hasSuffix("n") ?? false
        return WeatherScenario(temp: Int(response.main.temp), condition: weatherInfo?.description.capitalized ?? "", type: type, isNight: isNight, feelsLike: Int(response.main.feels_like), date: Date())
    }
    
    private func createForecastScenario(from item: ForecastItem) -> WeatherScenario {
        let weatherInfo = prioritizeWeather(item.weather)
        let type = mapWeatherType(id: weatherInfo?.id ?? 800, temp: item.main.temp)
        return WeatherScenario(temp: Int(item.main.temp), condition: weatherInfo?.description.capitalized ?? "", type: type, isNight: false, feelsLike: Int(item.main.feels_like), date: Date(timeIntervalSince1970: item.dt))
    }
    
    private func prioritizeWeather(_ weatherList: [WeatherInfo]) -> WeatherInfo? {
        if let severe = weatherList.first(where: { $0.id < 700 }) { return severe }
        return weatherList.first
    }
    
    private func mapWeatherType(id: Int, temp: Double) -> WeatherType {
        switch id {
        case 200...232: return .thunderstorm
        case 300...321: return .drizzle
        case 500...531: return .rainy
        case 600...622: return .snowy
        case 701...781: return .fog
        case 800: return temp < 10 ? .clearCold : .sunny
        case 801...804: return .cloudy
        default: return .cloudy
        }
    }
    
    func getFormattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: date)
    }
}
