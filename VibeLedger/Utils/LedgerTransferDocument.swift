import SwiftUI
import UniformTypeIdentifiers

struct LedgerTransferDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let transfer: LedgerTransfer

    init(transfer: LedgerTransfer) {
        self.transfer = transfer
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.transfer = try Self.decodeTransfer(from: data)
    }

    init(data: Data) throws {
        self.transfer = try Self.decodeTransfer(from: data)
    }

    private static func decodeTransfer(from data: Data) throws -> LedgerTransfer {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LedgerTransfer.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(transfer)
        return .init(regularFileWithContents: data)
    }
}
