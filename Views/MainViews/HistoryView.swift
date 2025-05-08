//  HistoryView.swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject var viewModel: HistoryViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sessionsByDate.keys.sorted(by: >), id: \.self) { date in
                    Section(header:
                        HStack {
                            Text(viewModel.formattedDate(date))
                            Spacer()
                            Text(viewModel.formatTotalTime(for: date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    ) {
                        ForEach(viewModel.sessionsByDate[date] ?? []) { session in
                            SessionListItemView(session: session)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            viewModel.deleteSession(session)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.loadSessions()
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(HistoryViewModel(
            modelContext: try! ModelContainer(for: Session.self).mainContext
        ))
}
