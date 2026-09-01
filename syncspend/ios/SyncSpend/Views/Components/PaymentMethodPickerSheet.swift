import SwiftUI

public struct PaymentMethodPickerSheet: View {
    @Binding public var selectedPaymentMethod: String
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedPaymentMethod: Binding<String>) {
        self._selectedPaymentMethod = selectedPaymentMethod
    }
    
    public let paymentMethods = [
        "Apple Pay",
        "Credit Card",
        "Debit Card",
        "Cash",
        "EFT / Bank Transfer"
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Payment Method")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.black.opacity(0.15))
                }
            }
            .padding(16)
            
            Divider()
            
            VStack(spacing: 0) {
                ForEach(paymentMethods, id: \.self) { method in
                    let isSelected = selectedPaymentMethod == method
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedPaymentMethod = method
                        dismiss()
                    } label: {
                        HStack {
                            Text(method)
                                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.primaryDark)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                }
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .presentationDetents([.fraction(0.4), .medium])
    }
}
