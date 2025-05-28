//
//  Selected3dFurnitureViewController.swift
//  test3
//
//  Created by 이택 on 5/16/25.
//

import Foundation
import UIKit
import QuickLook


class Selected3dFurnitureViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    weak var furnitureDelegate: FurnitureSelectionDelegate?

    @IBOutlet weak var tableView: UITableView!
    
    
    
    // QuickLook Preview용
    var selectedUSDZURL: URL?

    let usdzFiles = ["furniture_chair_swan", "furniture_gramophone", "furniture_teapot","Ceiling_Light"]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    
    // 📌 UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usdzFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "usdzCell", for: indexPath)
        cell.textLabel?.text = usdzFiles[indexPath.row]
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileName = usdzFiles[indexPath.row]
        
        furnitureDelegate?.didSelectUSDZModel(named: fileName)
        print("✅ \(fileName).usdz 선택 → SCNView에 선택됨")

        dismiss(animated: true)
    }

}


extension Selected3dFurnitureViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return selectedUSDZURL! as NSURL
    }
}


protocol FurnitureSelectionDelegate: AnyObject {
    func didSelectUSDZModel(named fileName: String)
}
