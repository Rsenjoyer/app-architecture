import Foundation


class Item: NSObject {
	let uuid: UUID
	private(set) var name: String
	weak var store: Store?
	weak var parent: Folder? {
		didSet {
			store = parent?.store
		}
	}
	
	init(name: String, uuid: UUID) {
		self.name = name
		self.uuid = uuid
		self.store = nil
	}
	
	func setName(_ newName: String) {
		name = newName
		if let p = parent {
			let (oldIndex, newIndex) = p.reSort(changedItem: self)
			store?.save(self, userInfo: [Item.changeReasonKey: Item.renamed, Item.oldValueKey: oldIndex, Item.newValueKey: newIndex, Item.parentFolderKey: p])
		}
	}
	
	func deleted() {
		parent = nil
	}
	
	func remove() {
		parent?.remove(self)
	}

	var uuidPath: [UUID] {
		return  (parent?.uuidPath ?? []) + [uuid]
	}

	func item(atUUIDPath path: ArraySlice<UUID>) -> Item? {
		return path.isEmpty ? self : nil
	}

	static func load(json: Any) -> Item? {
		guard let dict = json as? [String: Any],
			let name = dict[.nameKey] as? String,
			let uuidString = dict[.uuidKey] as? String,
			let uuid = UUID(uuidString: uuidString),
			let isFolder = dict[.isFolderKey] as? Bool
			else {
				return nil
		}
		if isFolder {
			return Folder(name: name, uuid: uuid, dict: dict)
		} else {
			return Recording(name: name, uuid: uuid)
		}
	}
	
	var json: [String: Any] {
		return [.nameKey: name, .uuidKey: uuid.uuidString, .isFolderKey: self is Folder]
	}
}

extension Item {
	var latestChange: Change? {
		return store?.latestChange(for: self)
	}
	
	var nextChange: Change? {
		return store?.nextChange(for: self)
	}
}


fileprivate extension String {
	static let nameKey = "name"
	static let uuidKey = "uuid"
	static let isFolderKey = "isFolder"
}

extension Item {
	static let changeReasonKey = "reason"
	static let newValueKey = "newValue"
	static let oldValueKey = "oldValue"
	static let parentFolderKey = "parentFolder"
	static let renamed = "renamed"
	static let added = "added"
	static let removed = "removed"
	static let reloaded = "reloaded"
}

