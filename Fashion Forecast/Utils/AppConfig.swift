//
//  AppConfig.swift
//  Fashion Forecast
//
//  Uygulama genelinde kullanılan sabit veriler, ayarlar ve anahtarlar.
//

import Foundation
import SwiftUI

enum AppConfig {
    
    // MARK: - API Yapılandırması
    struct API {
        // Anahtarlar Secrets.swift dosyasından çekiliyor.
        // Secrets.swift dosyası .gitignore ile gizlenmiştir.
        static let openWeatherMapKey = Secrets.openWeatherMapKey
        static let geminiKey = Secrets.geminiKey
        
        static let weatherBaseURL = "https://api.openweathermap.org/data/2.5"
        static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models"
        static let geminiModel = "gemini-2.5-flash-lite"
    }
    
    // MARK: - Sabit Veriler
    static let availableIcons = [
        "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "leaf.fill", "hare.fill", "eyeglasses", "mustache.fill",
        "crown.fill", "briefcase.fill", "music.note", "airplane"
    ]
    
    // MARK: - Tasarım Ayarları
    struct Layout {
        static let standardSpacing: CGFloat = 20
        // Arama çubuğunun üstten ne kadar aşağıda olacağı
        static let searchBarTopPadding: CGFloat = 60
    }
}
