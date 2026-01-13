//
//  Models.swift
//  Fashion Forecast
//
//  Created by Sadettin Karadavut on 10.12.2025.
//

import Foundation
import SwiftUI

// MARK: - API Response Modelleri

struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [WeatherInfo]
    let name: String
    let dt: TimeInterval
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
    let city: CityInfo
}

struct ForecastItem: Codable {
    let dt: TimeInterval
    let main: MainWeather
    let weather: [WeatherInfo]
    let dt_txt: String
}

struct CityInfo: Codable {
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
    let feels_like: Double
}

struct WeatherInfo: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

// MARK: - Uygulama İçi Modeller

struct StyleItem: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var isRemovable: Bool
}

struct WeatherScenario {
    let temp: Int
    let condition: String
    let type: WeatherType
    let isNight: Bool
    let feelsLike: Int
    let date: Date
}

enum WeatherType: CaseIterable {
    case sunny, clearCold, cloudy, rainy, snowy, thunderstorm, drizzle, fog
    
    var title: String {
        switch self {
        case .sunny: return "Güneşli"
        case .clearCold: return "Ayaz"
        case .cloudy: return "Bulutlu"
        case .rainy: return "Yağmurlu"
        case .snowy: return "Karlı"
        case .thunderstorm: return "Fırtına"
        case .drizzle: return "Çiseleme"
        case .fog: return "Sisli"
        }
    }
    
    func getIconName(isNight: Bool) -> String {
        switch self {
        case .sunny: return isNight ? "moon.stars.fill" : "sun.max.fill"
        case .clearCold: return isNight ? "moon.fill" : "sun.max.fill"
        case .cloudy: return isNight ? "cloud.moon.fill" : "cloud.fill"
        case .rainy: return isNight ? "cloud.moon.rain.fill" : "cloud.rain.fill"
        case .snowy: return "snowflake"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .fog: return "cloud.fog.fill"
        }
    }
    
    func getGradientColors(isNight: Bool) -> [Color] {
        if isNight {
            switch self {
            case .sunny, .clearCold: return [Color(red: 0.01, green: 0.01, blue: 0.08), Color(red: 0.09, green: 0.11, blue: 0.28)]
            case .cloudy: return [Color(red: 0.05, green: 0.07, blue: 0.15), Color(red: 0.15, green: 0.18, blue: 0.30)]
            case .rainy, .thunderstorm, .drizzle: return [Color(red: 0.02, green: 0.02, blue: 0.05), Color(red: 0.1, green: 0.1, blue: 0.2)]
            case .snowy, .fog: return [Color(red: 0.08, green: 0.10, blue: 0.20), Color(red: 0.20, green: 0.25, blue: 0.35)]
            }
        } else {
            switch self {
            case .sunny: return [Color(red: 0.29, green: 0.67, blue: 0.95), Color(red: 1.0, green: 0.85, blue: 0.4)]
            case .clearCold: return [Color(red: 0.2, green: 0.4, blue: 0.7), Color(red: 0.7, green: 0.9, blue: 1.0)]
            case .cloudy: return [Color(red: 0.4, green: 0.5, blue: 0.6), Color(red: 0.8, green: 0.85, blue: 0.9)]
            case .rainy: return [Color(red: 0.15, green: 0.2, blue: 0.3), Color(red: 0.25, green: 0.35, blue: 0.45)]
            case .snowy: return [Color(red: 0.5, green: 0.65, blue: 0.85), Color(red: 0.9, green: 0.95, blue: 1.0)]
            case .thunderstorm: return [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.25, green: 0.2, blue: 0.35)]
            case .drizzle: return [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.7, green: 0.8, blue: 0.85)]
            case .fog: return [Color(red: 0.6, green: 0.65, blue: 0.7), Color(red: 0.8, green: 0.8, blue: 0.82)]
            }
        }
    }
    
    var buttonGradient: [Color] {
        switch self {
        case .sunny: return [Color.orange, Color.red]
        case .clearCold: return [Color.indigo, Color.purple]
        case .cloudy: return [Color(red: 0.3, green: 0.4, blue: 0.5), Color(red: 0.5, green: 0.6, blue: 0.7)]
        case .rainy: return [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.2, green: 0.3, blue: 0.4)]
        case .snowy: return [Color.blue, Color.cyan]
        case .thunderstorm: return [Color.purple, Color.black]
        case .drizzle: return [Color.teal, Color.blue]
        case .fog: return [Color.gray, Color(white: 0.4)]
        }
    }
}

// MARK: - Gemini Modelleri

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let safetySettings: [GeminiSafetySetting]?
    let generationConfig: GeminiGenerationConfig?
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String?
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiSafetySetting: Codable {
    let category: String
    let threshold: String
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiErrorDetails?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
}

struct GeminiErrorDetails: Codable {
    let message: String?
    let code: Int?
    let status: String?
}
