//
//  ViewController.swift
//  LPResourceFilter
//
//  Created by pengli on 2019/8/7.
//  Copyright © 2019 pengli. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var filePathTextField1: NSTextField!
    @IBOutlet weak var filePathTextField2: NSTextField!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet var resultTextView: NSTextView!
    private var fileURL1: URL?
    private var fileURL2: URL?
    private var imageNames1: [String] = []
    private var imageNames2: [String] = []
    private var imageNameFilters: [String] = []
    
    @IBAction func chooseFileButtonClicked(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.resolvesAliases = false
        panel.canChooseFiles = true
        panel.begin { (result) in
            guard result == .OK else { return }
            if sender.tag == 1000 {
                self.fileURL1 = panel.urls.first
                self.filePathTextField1.stringValue = self.fileURL1!.path
            } else {
                self.fileURL2 = panel.urls.first
                self.filePathTextField2.stringValue = self.fileURL2!.path
            }
        }
    }

    @IBAction func startAnalyzeButtonClicked(_ sender: Any) {
        guard let fileURL1 = fileURL1, FileManager.default.fileExists(atPath: fileURL1.path)
            , let fileURL2 = fileURL2, FileManager.default.fileExists(atPath: fileURL2.path)
            else { return showAlert(with: "请选择正确的文件路径") }
        
        self.indicator.isHidden = false
        self.indicator.startAnimation(self)
        DispatchQueue.global().async {
            var imageNames1: [String] = []
            if fileURL1.path.hasSuffix(".txt") {
                if let images = try? String(contentsOf: fileURL1, encoding: .macOSRoman) {
                    imageNames1 = images.components(separatedBy: "\n")
                }
            } else {
                FileManager.default.subpaths(atPath: fileURL1.path)?.forEach({
                    if $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".gif") {
                        if let range = $0.range(of: "/", options: .backwards) {
                            imageNames1.append(String($0[range.upperBound..<$0.endIndex]))
                        }
                    }
                })
            }
            var imageNames2: [String] = []
            if fileURL2.path.hasSuffix(".txt") {
                if let images = try? String(contentsOf: fileURL2, encoding: .macOSRoman) {
                    imageNames2 = images.components(separatedBy: "\n")
                }
            } else {
                FileManager.default.subpaths(atPath: fileURL2.path)?.forEach({
                    if $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".gif") {
                        if let range = $0.range(of: "/", options: .backwards) {
                            imageNames2.append(String($0[range.upperBound..<$0.endIndex]))
                        }
                    }
                })
            }
            var imageNameFilters: [String] = []
            imageNames2.forEach({
                if !imageNames1.contains($0) { imageNameFilters.append($0) }
            })
            
            self.imageNames1 = imageNames1
            self.imageNames2 = imageNames2
            self.imageNameFilters = imageNameFilters
            
            let result: String =
            """
            历史图片数量：\(imageNames1.count)
            当前图片数量：\(imageNames2.count)
            当前新添加的图片数量：\(imageNameFilters.count)
            当前新添加的图片名称：
            \(imageNameFilters.joined(separator: "\n"))
            """
            DispatchQueue.main.async {
                self.resultTextView.string = result
                self.indicator.isHidden = true
                self.indicator.stopAnimation(self)
            }
        }
    }

    @IBAction func outputButtonClicked(_ sender: Any) {
        if imageNameFilters.count == 0 {
            return showAlert(with: "请点击开始，后再保存")
        }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.resolvesAliases = false
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.message = "请选择文件的保存位置"
        panel.begin { (result) in
            guard result == .OK, let document = panel.urls.first else { return }
            
            do {
                let file1 = document.path + "/LPImageName1.txt"
                let file2 = document.path + "/LPImageName2.txt"
                let filter = document.path + "/LPImageNameFilter.txt"
                try self.imageNames1.joined(separator: "\n").write(toFile: file1, atomically: true, encoding: .utf8)
                try self.imageNames2.joined(separator: "\n").write(toFile: file2, atomically: true, encoding: .utf8)
                try self.resultTextView.string.write(toFile: filter, atomically: true, encoding: .utf8)
            } catch {
                print(error)
            }
        }
    }
    
    private func showAlert(with text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.addButton(withTitle: "确定")
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }
}

