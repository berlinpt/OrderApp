//
//  OrderTableViewController.swift
//  OrderApp
//
//  Created by Berlin Thomas on 2024-04-06.
//

import UIKit

class OrderTableViewController: UITableViewController {
    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    var minutesToPrepareOrder = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        NotificationCenter.default.addObserver(tableView!, selector: #selector(UITableView.reloadData), name: MenuController.orderUpdatedNotification, object: nil)
    
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(with: .order)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Cancel image fetching tasks that are no longer needed
        imageLoadTasks.forEach { key, value in value.cancel() }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuController.shared.order.menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order", for: indexPath)

        configure(cell, forItemAt: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            MenuController.shared.order.menuItems.remove(at: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cancel the image fetching task if it's no longer needed
        imageLoadTasks[indexPath]?.cancel()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    @IBSegueAction func confirmOrder(_ coder: NSCoder) -> OrderConfirmationViewController? {
        return OrderConfirmationViewController(coder: coder, minutesToPrepare: minutesToPrepareOrder)
    }
    
    @IBAction func unwindToOrderList(segue: UIStoryboardSegue) {
        if segue.identifier == "dismissConfirmation" {
            MenuController.shared.order.menuItems.removeAll()
        }
    }
    
    
    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? MenuItemCell else { return }
        
        let menuItem = MenuController.shared.order.menuItems[indexPath.row]
        
        
        cell.itemName = menuItem.name
        cell.price = menuItem.price
        cell.image = nil
        
        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for: cell), currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
        
    }
    
    
    @IBAction func submitTapped(_ sender: Any) {
        let orderTotal = MenuController.shared.order.menuItems.reduce(0.0) {
            (result, menuItem) -> Double in
            return result + menuItem.price
        }
        
        let formattedTotal = orderTotal.formatted(.currency(code: "usd"))
        let alertController = UIAlertController(title: "Confirm order", message: "You are about to submit your order with a total of \(formattedTotal)", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Submit", style: .default, handler: { _ in
            self.uploadOrder()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map { $0.id }
        
        Task.init {
            do {
                let minutesToPrepare = try await MenuController.shared.submitOrder(forMenuIDs: menuIds)
                minutesToPrepareOrder = minutesToPrepare
                performSegue(withIdentifier: "confirmOrder", sender: nil)
            }
            catch {
                displayError(error, title: "Order Submission Failed")
            }
        }
    }
    
    func displayError(_ error: Error, title: String) {
        guard let _ = viewIfLoaded?.window else { return }
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

