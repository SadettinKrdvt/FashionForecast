//
//  StyleDropDelegate.swift
//  Fashion Forecast
//
//  Stil ikonlarının sürükle-bırak mantığını yönetir.
//  UI kodundan ayrılarak kodun okunabilirliğini artırır.
//

import SwiftUI
import UniformTypeIdentifiers

struct StyleDropDelegate: DropDelegate {
    // MARK: - Properties
    let item: StyleItem
    var viewModel: WeatherStyleViewModel // ViewModel referansı
    
    // MARK: - Drop Delegate Methods
    
    func dropEntered(info: DropInfo) {
        // ViewModel @MainActor olduğu için UI güncellemelerini ana thread'de yapıyoruz.
        Task { @MainActor in
            guard let draggedItem = viewModel.currentDraggedStyle,
                  draggedItem != item,
                  let from = viewModel.styles.firstIndex(of: draggedItem),
                  let to = viewModel.styles.firstIndex(of: item)
            else { return }
            
            // Animasyonlu sıralama değişimi
            if from != to {
                playHaptic(style: .soft) // Extensions.swift'ten gelen titreşim
                withAnimation {
                    viewModel.styles.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
                }
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Değişiklikleri kaydet ve sürükleme durumunu sıfırla
        Task { @MainActor in
            viewModel.saveStyles()
            viewModel.currentDraggedStyle = nil
            playHaptic(style: .medium) // Başarılı işlem titreşimi
        }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal {
        return DropProposal(operation: .move)
    }
}
