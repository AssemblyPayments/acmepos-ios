//
//  MainViewController+Actions.swift
//  TablePos
//
//  Created by Amir Kamali on 29/5/18.
//  Copyright © 2018 mx51. All rights reserved.
//

import Foundation
import SPIClient_iOS

extension MainViewController {
    
    @IBAction func btnOpenTableClicked(_ sender: Any) {         
        let tableId = txtTableId.text?.trimmingCharacters(in: .whitespacesAndNewlines)        
        let tableIdRegex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9]*$")
        let match = tableIdRegex.numberOfMatches(in: tableId!, options: [], range: NSMakeRange(0, tableId!.count));
        
        if (tableId!.count != 0 && match == 0) {
            showMessage(title: "Open Table", msg: "The Pos Id can not include special characters", type: "WARNING", isShow: true)
            return
        }
        
        if TableApp.current.tableToBillMapping[tableId!] != nil {
            let bill: Bill = TableApp.current.billsStore[TableApp.current.tableToBillMapping[tableId!]!]!
            showMessage(title: "Open Table", msg: "Table Already Open: \(bill.toString())", type: "WARNING", isShow: true)
            return
        }
        
        let newBill = Bill()
        newBill.billId = newBillId()
        newBill.tableId = tableId!
        newBill.operatorId = txtOperatorId.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        newBill.label = txtLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        newBill.locked = swchLockedTable.isOn
        
        TableApp.current.billsStore[newBill.billId!] = newBill
        TableApp.current.tableToBillMapping[newBill.tableId!] = newBill.billId
        
        showMessage(title: "Open Table", msg: "Opened: \(newBill.toString())", type: "INFO", isShow: true)
    }
    
    @IBAction func btnAddTableClicked(_ sender: Any) {
        guard let amount = Int(txtTransactionAmount.text ?? ""), amount > 0 else { return }
        
        let tableId = txtTableId.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if TableApp.current.tableToBillMapping[tableId!] == nil {
            showMessage(title: "Add Table", msg: "Table not Open.", type: "WARNING", isShow: true)
            return
        }
        
        let bill: Bill = TableApp.current.billsStore[TableApp.current.tableToBillMapping[tableId!]!]!
        if bill.locked! {
            showMessage(title: "Add Table", msg: "Table is Locked.", type: "WARNING", isShow: true)
            return
        }
        
        bill.totalAmount! += amount
        bill.outstandingAmount! += amount
        
        showMessage(title: "Add Table", msg: "Updated: \(bill.toString())", type: "INFO", isShow: true)
    }
    
    @IBAction func btnLockUnlockTableClicked(_ sender: Any) {
        let tableId = txtTableId.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (TableApp.current.tableToBillMapping[tableId!] == nil) {
            showMessage(title: "Lock/UnLock Table", msg: "Table not Open.", type: "WARNING", isShow: true)
            return
        }
        
        let bill: Bill = TableApp.current.billsStore[TableApp.current.tableToBillMapping[tableId!]!]!
        bill.locked = swchLockedTable.isOn
        
        let msg: String = bill.locked! ? "Locked" : "UnLocked"
        showMessage(title: "Lock/UnLock Table", msg: "Table is \(msg): \(bill.toString())", type: "INFO", isShow: true)
    }
    
    @IBAction func btnCloseTableClicked(_ sender: Any) {
        let tableId = txtTableId.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if TableApp.current.tableToBillMapping[tableId!] == nil {
            showMessage(title: "Close Table", msg: "Table not Open.", type: "WARNING", isShow: true)
            return
        }
        
        let bill: Bill = TableApp.current.billsStore[TableApp.current.tableToBillMapping[tableId!]!]!
        if bill.locked! {
            showMessage(title: "Close Table", msg: "Table is Locked.", type: "WARNING", isShow: true)
            return
        }
        
        if (bill.outstandingAmount)! > 0 {
            showMessage(title: "Close Table", msg: "Bill not Paid Yet: \(bill.toString())", type: "WARNING", isShow: true)
            return
        }
        
        TableApp.current.tableToBillMapping.removeValue(forKey: tableId!)
        TableApp.current.mx51BillDataStore.removeValue(forKey: (bill.billId)!)
        showMessage(title: "Close Table", msg: "Closed: \(bill.toString())", type: "INFO", isShow: true)
    }
    
    @IBAction func btnListTablesClicked(_ sender: Any) {
        var listTables: String = "\n"
        if TableApp.current.tableToBillMapping.count > 0 {
            var openTables: String = ""
            for key in TableApp.current.tableToBillMapping.keys {
                if openTables != "" {
                    openTables += ",\n"
                }
                
                openTables += key
            }
            
            listTables = "#    Open Tables:\n\(openTables)\n"
        } else {
            showMessage(title: "List Tables", msg: "# No Open Tables.", type: "INFO", isShow: true)
        }
        
        if TableApp.current.billsStore.count > 0 {
            var openBills: String = ""
            for key in TableApp.current.billsStore.keys {
                if openBills != "" {
                    openBills += ",\n"
                }
                
                openBills += key
            }
            
            listTables += "# My Bills Store:\n\(openBills)\n"
        }
        
        if TableApp.current.mx51BillDataStore.count > 0 {
            var openBills: String = ""
            for key in TableApp.current.mx51BillDataStore.keys {
                if openBills != "" {
                    openBills += ",\n"
                }
                
                openBills += key
            }
            
            listTables = "# mx51 Bills Data:\n\(openBills)"
        }
        
        showMessage(title: "List Tables", msg: "\(listTables)", type: "INFO", isShow: true)
    }
    
    @IBAction func btnPrintTableClicked(_ sender: Any) {
        let tableId = txtTableId.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if (TableApp.current.tableToBillMapping[tableId!] == nil) {
            showMessage(title: "Print Table", msg: "Table not Open.", type: "WARNING", isShow: true)
            return
        }
        
        printBill(billId: TableApp.current.tableToBillMapping[tableId!]! , title: "Print Table")
    }
    
    @IBAction func btnPrintBillClicked(_ sender: Any) {
        printBill(billId: txtBillId.text!, title: "Print Bill")
    }
    
    @IBAction func btnRecoverClicked(_ sender: UIButton) {
        guard let referenceId = txtReferenceId.text else { return }
        TableApp.current.client.initiateRecovery(referenceId, transactionType: .getLastTransaction, completion: printResult)
    }
    
    @IBAction func btnPurchaseClicked(_ sender: Any) {
        let posRefId = "purchase-" + Date().toString(format: "dd-MM-yyyy-HH-mm-ss")
        
        guard let amount = Int(txtTransactionAmount.text ?? ""), amount > 0 else { return }
        
        // Receipt header/footer
        let options = setReceiptHeaderFooter()
        
        client.initiatePurchaseTx(posRefId,
                                  purchaseAmount: amount,
                                  tipAmount: 0,
                                  cashoutAmount: 0,
                                  promptForCashout: false,
                                  options:options,
                                  completion: printResult)
    }
    
    @IBAction func btnRefundClicked(_ sender: Any) {
        let posRefId = "yuck-" + Date().toString(format: "dd-MM-yyyy-HH-mm-ss")
        let suppressMerchantPassword =  TableApp.current.settings.suppressMerchantPassword ?? false
        
        guard let amount = Int(txtTransactionAmount.text ?? ""), amount > 0 else { return }
        
        // Receipt header/footer
        let options = setReceiptHeaderFooter()
        
        client.initiateRefundTx(posRefId,
                                amountCents: amount,
                                suppressMerchantPassword: suppressMerchantPassword,
                                options: options,
                                completion: printResult)
    }
    
    @IBAction func btnSettleClicked(_ sender: Any) {
        let id = SPIRequestIdHelper.id(for: "settle")
        
        // Receipt header/footer
        let options = setReceiptHeaderFooter()
        
        client.initiateSettleTx(id,
                                options: options,
                                completion: printResult)
    }
    
    @IBAction func btnSetLabelOperatorIdClicked(_ sender:  Any) {
        spiPat.config.labelOperatorId = txtLabelOperatorId.text
        TableApp.current.settings.labelOperatorId = txtLabelOperatorId.text
        spiPat.pushConfig()
    }
    
    @IBAction func btnSetLabelTableIdClicked(_ sender: Any) {
        spiPat.config.labelTableId = txtLabelTableId.text
        TableApp.current.settings.labelTableId = txtLabelTableId.text
        spiPat.pushConfig()
    }
    
    @IBAction func btnSetLabelPayButtonClicked(_ sender: Any) {
        spiPat.config.labelPayButton = txtLabelPayButton.text
        TableApp.current.settings.labelPayButton = txtLabelPayButton.text
        spiPat.pushConfig()
    }
    
    @IBAction func btnAddAllowedOperatorIdClicked(_ sender: Any) {
        TableApp.current.allowedOperatorIds.append(txtAllowedOperatorId.text!)
        spiPat.config.allowedOperatorIds = TableApp.current.allowedOperatorIds
        spiPat.pushConfig()
    }
    
    @IBAction func btnSetPatAllEnabledClicked(_ sender: Any) {
        TableApp.current.enablePayAtTableConfig()
        swchPatEnabled.isOn = TableApp.current.settings.patEnabled ?? false
        swchOperatorIDEnabled.isOn = TableApp.current.settings.operatorIdEnabled ?? false
        swchEqualSplit.isOn = TableApp.current.settings.equalSplit ?? false
        swchSplitByAmount.isOn = TableApp.current.settings.splitByAmount ?? false
        swchTipping.isOn = TableApp.current.settings.tipping ?? false
        swchSummaryReport.isOn = TableApp.current.settings.summaryReport ?? false
        swchTableRetrievalButton.isOn = TableApp.current.settings.tableRetrievalButton ?? false
        txtLabelPayButton.text = TableApp.current.settings.labelPayButton
        txtLabelTableId.text = TableApp.current.settings.labelTableId
        txtLabelOperatorId.text = TableApp.current.settings.labelOperatorId
        spiPat.pushConfig()
    }
    
    func newBillId() -> String {
        let orginalDate = Date()
        return String(orginalDate.timeIntervalSince1970)
    }
    
    func printBill(billId: String, title: String) {
        let billId = billId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if TableApp.current.billsStore[billId] == nil {
            showMessage(title: title, msg: "Bill Not Found.", type: "ERROR", isShow: true)
            return
        }
        
        let bill: Bill = TableApp.current.billsStore[billId]! 
        showMessage(title: title, msg: "Bill: \(bill.toString())", type: "INFO", isShow: true)
    }
    
    func sanitizePrintText(_ text: String?) -> String? {
        var sanitizeText: String? = text?.replacingOccurrences(of: "\\r\\n", with: "\n");
        sanitizeText = sanitizeText?.replacingOccurrences(of: "\\n", with: "\n");
        sanitizeText = sanitizeText?.replacingOccurrences(of: "\\\\emphasis", with: "\\emphasis");
        return sanitizeText?.replacingOccurrences(of: "\\\\clear", with: "\\clear");
    }
    
    func showMessage(title: String, msg: String, type: String, isShow: Bool, completion: (() -> Swift.Void)? = nil) {
        logMessage("\(type): \(msg)")
        
        if isShow {
            showAlert(title: title, message: msg)
        }
    }
    
    func setReceiptHeaderFooter() -> SPITransactionOptions {
        let settings = TableApp.current.settings
        let options = SPITransactionOptions()
        
        if let receiptHeader = settings.receiptHeader, receiptHeader.count > 0 {
            options.customerReceiptHeader = sanitizePrintText(receiptHeader)
            options.merchantReceiptHeader = sanitizePrintText(receiptHeader)
        }
        if let receiptFooter = settings.receiptFooter, receiptFooter.count > 0 {
            options.customerReceiptFooter = sanitizePrintText(receiptFooter)
            options.merchantReceiptFooter = sanitizePrintText(receiptFooter)
        }
        
        return options
    }
}
