enum CellState {
  empty,        // Boş hücre
  markedEmpty,  // Tek Tık: "Burada hayvan yok" (X işareti)
  hasAnimal,    // Uzun Basma: Doğru tahmin edilen hayvan
  wrongAttempt  // Yanlış tahmin sonucu otomatik kilitlenen X durumu
}