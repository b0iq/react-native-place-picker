//
//  DropDown.swift
//  react-native-place-picker
//
//  Created by b0iq on 01/09/2023.
//

import UIKit
import MapKit.MKLocalSearchCompleter

protocol DropDownButtonDelegate: AnyObject {
    func didSelect(_ index: Int)
}

class DropDown: UIView {
    
    let tableView: UITableView = {
        let table: UITableView = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.isHidden = true
        table.backgroundView = UIView()
        table.backgroundColor = .none
        table.isOpaque = true
        table.register(DropdownTableViewCell.self, forCellReuseIdentifier: DropdownTableViewCell.reuseIdentifier)
        return table
    }()

    var dataSource: [CustomSearchCompletion] = [] {
        didSet {
            updateTableDataSource()
        }
    }

    var delegate: DropDownButtonDelegate?

    var tableViewHeight: NSLayoutConstraint?
    
    var maxVisibleCellsAmount: Int = 10 {
        didSet {
            updateTableDataSource()
        }
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo:topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
        ])
        tableViewHeight?.isActive = true
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: "CELL")
    }

    func updateTableDataSource() {
        self.tableView.isHidden = dataSource.count < 1
        tableView.reloadData()
    }
}

extension DropDown: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath)
        let row = dataSource[indexPath.row]
        cell.textLabel?.attributedText = row.attrTitle
        cell.detailTextLabel?.attributedText = row.attrSubtitle
        return cell
    }

}

extension DropDown: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelect(indexPath.row)
        return
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight
    }
}
class SubtitleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.isOpaque = true
        if #available(iOS 13.0, *) {
            self.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        } else {
            self.backgroundColor = .white.withAlphaComponent(0.8)
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

