//
//  AddStyleSheet.swift
//  Fashion Forecast
//
//  Yeni stil ekleme formu.
//  Kullanıcının ikon seçip isim girerek yeni bir kategori oluşturmasını sağlar.
//

import SwiftUI

struct AddStyleSheet: View {
    // MARK: - Properties
    @Binding var isPresented: Bool
    let availableIcons: [String]
    var onAdd: (String, String) -> Void
    
    // MARK: - State
    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Bölüm 1: İsim Girişi
                Section(header: Text("Tarz Bilgisi")) {
                    TextField("Tarz Adı (Örn: Bohem)", text: $name)
                }
                
                // Bölüm 2: İkon Seçimi
                Section(header: Text("İkon Seç")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 20) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .blue : .gray)
                                .frame(width: 44, height: 44) // Dokunma alanı genişletildi
                                .background(selectedIcon == icon ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    playHaptic(style: .light) // Seçim titreşimi
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Yeni Tarz Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        playHaptic(style: .medium) // Onay titreşimi
                        onAdd(name, selectedIcon)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// Önizleme için (Xcode Previews)
#Preview {
    AddStyleSheet(
        isPresented: .constant(true),
        availableIcons: ["star.fill", "heart.fill", "bolt.fill"],
        onAdd: { _, _ in }
    )
}
