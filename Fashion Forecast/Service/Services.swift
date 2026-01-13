//
//  Services.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import Foundation

// MARK: - Hata Tipleri
enum ServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL yapısı."
        case .invalidResponse: return "Sunucudan hatalı yanıt alındı."
        case .apiError(let msg): return "API Hatası: \(msg)"
        case .decodingError: return "Veri işlenemedi."
        }
    }
}

// MARK: - Hava Durumu Servisi
class WeatherService {
    
    // Generic Network Fetcher (Kod tekrarını önleyen yapı)
    private func fetchData<T: Decodable>(endpoint: String, queryItems: [URLQueryItem]) async throws -> T {
        var components = URLComponents(string: "\(AppConfig.API.weatherBaseURL)/\(endpoint)")
        
        let commonQueryItems = [
            URLQueryItem(name: "appid", value: AppConfig.API.openWeatherMapKey),
            URLQueryItem(name: "lang", value: "tr"),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        components?.queryItems = commonQueryItems + queryItems
        
        guard let url = components?.url else { throw ServiceError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw ServiceError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Weather Decode Hatası: \(error)")
            throw ServiceError.decodingError
        }
    }
    
    // MARK: - Public Methods
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        let items = [URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lon", value: "\(lon)")]
        return try await fetchData(endpoint: "weather", queryItems: items)
    }
    
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        let items = [URLQueryItem(name: "lat", value: "\(lat)"), URLQueryItem(name: "lon", value: "\(lon)")]
        return try await fetchData(endpoint: "forecast", queryItems: items)
    }
    
    func fetchCurrentWeather(city: String) async throws -> WeatherResponse {
        return try await fetchData(endpoint: "weather", queryItems: [URLQueryItem(name: "q", value: city)])
    }
    
    func fetchForecast(city: String) async throws -> ForecastResponse {
        return try await fetchData(endpoint: "forecast", queryItems: [URLQueryItem(name: "q", value: city)])
    }
}

// MARK: - Yapay Zeka Servisi (Gemini)
class GeminiService {
    
    func generateAdvice(prompt: String) async throws -> String {
        let cleanKey = AppConfig.API.geminiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { throw ServiceError.apiError("API Anahtarı eksik.") }
        
        guard let url = URL(string: "\(AppConfig.API.geminiBaseURL)/\(AppConfig.API.geminiModel):generateContent?key=\(cleanKey)") else {
            throw ServiceError.invalidURL
        }
        
        let content = GeminiContent(parts: [GeminiPart(text: prompt)], role: "user")
        let requestBody = GeminiRequest(
            contents: [content],
            safetySettings: nil,
            generationConfig: GeminiGenerationConfig(temperature: 0.8)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 { throw ServiceError.apiError("Çok fazla istek. Lütfen bekleyin.") }
            guard 200...299 ~= httpResponse.statusCode else { throw ServiceError.invalidResponse }
        }
        
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        if let text = decoded.candidates?.first?.content?.parts.first?.text {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let errorDetail = decoded.error {
            throw ServiceError.apiError(errorDetail.message ?? "Bilinmiyor")
        }
        
        throw ServiceError.apiError("Tavsiye alınamadı.")
    }
}
