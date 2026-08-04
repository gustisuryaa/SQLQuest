import SwiftUI

// MARK: - RawDataView
// Displays the raw source tables so users understand the underlying data
// before exploring how JOINs combine them.

struct RawDataView: View {
    @ObservedObject var viewModel: JoinViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Table A — Students
                Section {
                    HStack {
                        Text("id")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundColor(.blue).frame(width: 40, alignment: .leading)
                        Text("name")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundColor(.blue)
                    }
                    .listRowBackground(Color.blue.opacity(0.06))

                    ForEach(viewModel.students) { student in
                        HStack {
                            Text("\(student.id)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary).frame(width: 40, alignment: .leading)
                            Text(student.name).font(.body.weight(.semibold))
                        }
                    }
                } header: {
                    Label("Table A: Students", systemImage: "person.2.fill")
                        .font(.subheadline.weight(.bold)).foregroundColor(.blue).textCase(nil)
                }

                // Table B — Clubs
                Section {
                    HStack {
                        Text("id")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundColor(.orange).frame(width: 40, alignment: .leading)
                        Text("club_name")
                            .font(.system(.caption, design: .monospaced).weight(.bold))
                            .foregroundColor(.orange)
                    }
                    .listRowBackground(Color.orange.opacity(0.06))

                    ForEach(viewModel.clubs) { club in
                        HStack {
                            Text("\(club.id)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary).frame(width: 40, alignment: .leading)
                            Text(club.clubName).font(.body.weight(.semibold))
                        }
                    }
                } header: {
                    Label("Table B: Clubs", systemImage: "person.3.fill")
                        .font(.subheadline.weight(.bold)).foregroundColor(.orange).textCase(nil)
                }

                // Schema note
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "key.fill").foregroundColor(.purple).font(.callout)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Join Key").font(.subheadline.weight(.bold))
                            Text("Students.id is matched against Clubs.id. Rows sharing the same value are a \"match\".")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Schema", systemImage: "info.circle")
                        .font(.subheadline.weight(.bold)).textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Source Tables")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(.body.weight(.semibold))
                }
            }
        }
    }
}
