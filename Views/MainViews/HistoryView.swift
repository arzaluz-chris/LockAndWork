//  HistoryView.swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject var viewModel: HistoryViewModel
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessionsByDate.isEmpty {
                    // Show empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 70))
                            .foregroundColor(.secondary)
                        
                        Text("No sessions yet")
                            .font(.title2)
                        
                        Text("Complete your first session to see it here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Show sessions
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
                    .refreshable {
                        isRefreshing = true
                        viewModel.loadSessions()
                        isRefreshing = false
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
