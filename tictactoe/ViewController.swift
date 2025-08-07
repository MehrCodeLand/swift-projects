import UIKit

// Enhanced data structures for game moves and machine learning
struct Move: Codable {
    let user: String                // Player who made the move
    let symbol: String              // X or O
    let cell: Int                   // Position (0-8)
    let moveNumber: Int             // Sequential move number
    
    // Board states
    let boardStateBefore: [String]  // Board state before this move
    let boardStateAfter: [String]   // Board state after this move
    
    // Valid moves
    let validMovesMask: [Bool]      // Which cells are available (true = valid)
    
    // Strategy classification
    let strategy: String            // "opening", "attacking", "blocking"
    let isWinningMove: Bool         // Did this move win the game
}

struct GameResult: Codable {
    let winner: String?             // Winner of the game, nil for draw
    let moves: [Move]               // All moves in the game
    let date: Date                  // When the game was played
    let gameId: String              // Unique identifier for the game
    let totalMoves: Int             // Total number of moves in the game
    let gameLength: TimeInterval?   // Duration of the game in seconds
}

class ViewController: UIViewController {
    
    // Game board
    private var buttons: [UIButton] = []
    private var currentPlayer = "Stalin" // Stalin starts with X
    private var currentSymbol = "X"
    private var gameActive = true
    private var moveCount = 0
    private var moves: [Move] = []
    private var gameResults: [GameResult] = []
    private var gameStartTime: Date?
    
    // Board state tracking
    private var boardState: [String] = Array(repeating: "", count: 9)
    
    // UI Elements
    private let statusLabel = UILabel()
    private let resetButton = UIButton()
    private let exportButton = UIButton()
    private let gridView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedData()
        resetGame() // Initialize the game
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Tic-Tac-Toe ML Data Collector"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Game grid
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.backgroundColor = .lightGray
        view.addSubview(gridView)
        
        // Status label
        statusLabel.text = "Player: Stalin (X)"
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Reset button
        resetButton.setTitle("New Game", for: .normal)
        resetButton.backgroundColor = .systemBlue
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 8
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        view.addSubview(resetButton)
        
        // Export button
        exportButton.setTitle("Export Data", for: .normal)
        exportButton.backgroundColor = .systemGreen
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.layer.cornerRadius = 8
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(exportData), for: .touchUpInside)
        view.addSubview(exportButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Grid
            gridView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            gridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            gridView.heightAnchor.constraint(equalTo: gridView.widthAnchor),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Buttons
            resetButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 160),
            resetButton.heightAnchor.constraint(equalToConstant: 44),
            
            exportButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 10),
            exportButton.centerXAnchor.constraint(equalTo: resetButton.centerXAnchor),
            exportButton.widthAnchor.constraint(equalTo: resetButton.widthAnchor),
            exportButton.heightAnchor.constraint(equalTo: resetButton.heightAnchor)
        ])
        
        // Setup the 3x3 grid of buttons
        createGameButtons()
    }
    
    private func createGameButtons() {
        // Clear any existing buttons
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons.removeAll()
        
        // Calculate button size
        let gridSize = gridView.bounds.width > 0 ? gridView.bounds.width : (view.bounds.width * 0.8)
        let buttonSize = gridSize / 3
        
        // Create 3x3 buttons
        for row in 0..<3 {
            for col in 0..<3 {
                let button = UIButton(type: .system)
                let index = row * 3 + col
                
                button.backgroundColor = .white
                button.setTitle("", for: .normal)
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .bold)
                button.tag = index
                button.layer.borderWidth = 1
                button.layer.borderColor = UIColor.darkGray.cgColor
                
                gridView.addSubview(button)
                
                // Set button frame - we'll use frames directly since this is a simple grid
                button.frame = CGRect(
                    x: CGFloat(col) * buttonSize,
                    y: CGFloat(row) * buttonSize,
                    width: buttonSize,
                    height: buttonSize
                )
                
                button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
                buttons.append(button)
            }
        }
    }
    
    // Ensure buttons are properly laid out when the view size changes
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // If the grid size changed, recreate the buttons
        if gridView.bounds.size != .zero && buttons.count != 9 {
            createGameButtons()
        } else if buttons.count == 9 {
            // Update button frames if needed
            let buttonSize = gridView.bounds.width / 3
            
            for index in 0..<9 {
                let row = index / 3
                let col = index % 3
                buttons[index].frame = CGRect(
                    x: CGFloat(col) * buttonSize,
                    y: CGFloat(row) * buttonSize,
                    width: buttonSize,
                    height: buttonSize
                )
            }
        }
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let cell = sender.tag
        
        // Check if the cell is already filled or game is not active
        if boardState[cell] != "" || !gameActive {
            return
        }
        
        // Capture the board state before the move
        let boardStateBefore = boardState.map { $0 }
        
        // Update button with X or O
        sender.setTitle(currentSymbol, for: .normal)
        boardState[cell] = currentSymbol
        
        // Calculate the valid moves mask (true for empty cells)
        let validMovesMask = boardState.map { $0 == "" }
        
        // Determine the strategy for this move
        let strategy = determineStrategy(at: cell)
        
        // Check if this is a winning move
        let isWinningMove = checkForWin()
        
        // Record the move with enhanced data
        moveCount += 1
        let move = Move(
            user: currentPlayer,
            symbol: currentSymbol,
            cell: cell,
            moveNumber: moveCount,
            boardStateBefore: boardStateBefore,
            boardStateAfter: boardState,
            validMovesMask: validMovesMask,
            strategy: strategy,
            isWinningMove: isWinningMove
        )
        moves.append(move)
        
        if isWinningMove {
            gameActive = false
            statusLabel.text = "Player \(currentPlayer) (\(currentSymbol)) wins!"
            saveGameResult(winner: currentPlayer)
        } else if moveCount == 9 { // All cells filled
            gameActive = false
            statusLabel.text = "Game ended in a draw!"
            saveGameResult(winner: nil)
        } else {
            // If game continues, switch player
            switchPlayer()
        }
    }
    
    private func determineStrategy(at cell: Int) -> String {
        // Strategy 1: "blocking" - preventing opponent from winning
        if isBlockingMove(at: cell) {
            return "blocking"
        }
        
        // Strategy 2: "attacking" - creating two in a row or winning
        if isAttackingMove(at: cell) {
            return "attacking"
        }
        
        // Strategy 3: "opening" - has two or more empty adjacent cells
        if isOpeningMove(at: cell) {
            return "opening"
        }
        
        return "neutral" // Fallback
    }
    
    private func isBlockingMove(at cell: Int) -> Bool {
        // Check if the move blocks opponent from winning
        // Create a temporary board with opponent's symbol at this position
        var tempBoard = boardState.map { $0 } // Copy the board
        tempBoard[cell] = currentSymbol // Place our move
        
        let opponentSymbol = (currentSymbol == "X") ? "O" : "X"
        
        // Check if before our move, the opponent would have won by placing here
        var opponentTempBoard = boardState.map { $0 }
        opponentTempBoard[cell] = opponentSymbol
        
        return wouldWin(board: opponentTempBoard, symbol: opponentSymbol)
    }
    
    private func isAttackingMove(at cell: Int) -> Bool {
        // Create a temporary board with our move
        var tempBoard = boardState.map { $0 }
        tempBoard[cell] = currentSymbol
        
        // Check if this created two of our symbols in a row with an empty cell
        // or if it's a winning move
        
        // Define all winning combinations
        let winPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]
        
        for pattern in winPatterns {
            // Count our symbols and empty cells in this pattern
            var symbolCount = 0
            var emptyCount = 0
            
            for position in pattern {
                if tempBoard[position] == currentSymbol {
                    symbolCount += 1
                } else if tempBoard[position] == "" {
                    emptyCount += 1
                }
            }
            
            // If we have exactly 2 of our symbols and 1 empty cell in the pattern,
            // this is an attacking move
            if symbolCount == 2 && emptyCount == 1 {
                return true
            }
        }
        
        return false
    }
    
    private func isOpeningMove(at cell: Int) -> Bool {
        // Create a list of adjacent cells
        let adjacentCells: [[Int]] = [
            [0, 1, 3, 4],       // Adjacency for cell 0
            [0, 1, 2, 3, 4, 5],  // Adjacency for cell 1
            [1, 2, 4, 5],       // Adjacency for cell 2
            [0, 3, 4, 6, 7],    // Adjacency for cell 3
            [0, 1, 2, 3, 4, 5, 6, 7, 8], // Adjacency for cell 4 (center)
            [1, 2, 4, 5, 7, 8],  // Adjacency for cell 5
            [3, 6, 7],          // Adjacency for cell 6
            [3, 4, 5, 6, 7, 8],  // Adjacency for cell 7
            [4, 5, 7, 8]         // Adjacency for cell 8
        ]
        
        // Remove cell itself from its adjacency list
        let adjacentToCell = adjacentCells[cell].filter { $0 != cell }
        
        // Count empty adjacent cells
        var emptyAdjacentCount = 0
        for adjacentCell in adjacentToCell {
            if boardState[adjacentCell] == "" {
                emptyAdjacentCount += 1
            }
        }
        
        // Opening move has at least 2 empty adjacent cells
        return emptyAdjacentCount >= 2
    }
    
    private func wouldWin(board: [String], symbol: String) -> Bool {
        // Define winning combinations
        let winPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]
        
        for pattern in winPatterns {
            if board[pattern[0]] == symbol && board[pattern[1]] == symbol && board[pattern[2]] == symbol {
                return true
            }
        }
        return false
    }
    
    private func switchPlayer() {
        currentPlayer = (currentPlayer == "Stalin") ? "Lenin" : "Stalin"
        currentSymbol = (currentSymbol == "X") ? "O" : "X"
        statusLabel.text = "Player: \(currentPlayer) (\(currentSymbol))"
    }
    
    private func checkForWin() -> Bool {
        // Define winning combinations
        let winPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]
        
        for pattern in winPatterns {
            if boardState[pattern[0]] != "" &&
               boardState[pattern[0]] == boardState[pattern[1]] &&
               boardState[pattern[1]] == boardState[pattern[2]] {
                return true
            }
        }
        return false
    }
    
    @objc private func resetGame() {
        // Clear board
        for (index, button) in buttons.enumerated() {
            button.setTitle("", for: .normal)
            boardState[index] = ""
        }
        
        // Reset game state
        currentPlayer = "Stalin"
        currentSymbol = "X"
        gameActive = true
        moveCount = 0
        moves = []
        gameStartTime = Date()
        
        statusLabel.text = "Player: Stalin (X)"
    }
    
    private func saveGameResult(winner: String?) {
        // Calculate game duration
        var gameLength: TimeInterval? = nil
        if let startTime = gameStartTime {
            gameLength = Date().timeIntervalSince(startTime)
        }
        
        let gameResult = GameResult(
            winner: winner,
            moves: moves,
            date: Date(),
            gameId: UUID().uuidString,
            totalMoves: moveCount,
            gameLength: gameLength
        )
        
        gameResults.append(gameResult)
        saveDataToFile()
    }
    
    private func saveDataToFile() {
        // Get document directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not find documents directory")
            return
        }
        
        // Save as JSON
        let jsonURL = documentsDirectory.appendingPathComponent("tictactoe_ml_data.json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(gameResults)
            try jsonData.write(to: jsonURL)
            print("JSON data saved to: \(jsonURL.path)")
        } catch {
            print("Error saving JSON data: \(error)")
        }
        
        // Save as CSV
        let csvURL = documentsDirectory.appendingPathComponent("tictactoe_ml_data.csv")
        var csvString = "GameID,Date,Winner,MoveNumber,User,Symbol,Cell,Strategy,IsWinningMove,BoardStateBefore,BoardStateAfter,ValidMovesMask,GameLength\n"
        
        for game in gameResults {
            for move in game.moves {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateString = dateFormatter.string(from: game.date)
                
                // Format board states and valid moves mask as comma-separated strings
                let boardStateBefore = move.boardStateBefore.map { $0.isEmpty ? "_" : $0 }.joined(separator: ";")
                let boardStateAfter = move.boardStateAfter.map { $0.isEmpty ? "_" : $0 }.joined(separator: ";")
                let validMovesMask = move.validMovesMask.map { $0 ? "1" : "0" }.joined(separator: ";")
                
                csvString += "\(game.gameId),\(dateString),\(game.winner ?? "Draw"),\(move.moveNumber),\(move.user),\(move.symbol),\(move.cell),\(move.strategy),\(move.isWinningMove),\"\(boardStateBefore)\",\"\(boardStateAfter)\",\"\(validMovesMask)\",\(game.gameLength ?? 0)\n"
            }
        }
        
        do {
            try csvString.write(to: csvURL, atomically: true, encoding: .utf8)
            print("CSV data saved to: \(csvURL.path)")
        } catch {
            print("Error saving CSV data: \(csvURL.path)")
        }
    }
    
    private func loadSavedData() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let jsonURL = documentsDirectory.appendingPathComponent("tictactoe_ml_data.json")
        
        if FileManager.default.fileExists(atPath: jsonURL.path) {
            do {
                let data = try Data(contentsOf: jsonURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                gameResults = try decoder.decode([GameResult].self, from: data)
                print("Loaded \(gameResults.count) saved games")
            } catch {
                print("Error loading saved data: \(error)")
            }
        }
    }
    
    @objc private func exportData() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let jsonURL = documentsDirectory.appendingPathComponent("tictactoe_ml_data.json")
        let csvURL = documentsDirectory.appendingPathComponent("tictactoe_ml_data.csv")
        
        let activityViewController = UIActivityViewController(
            activityItems: [jsonURL, csvURL],
            applicationActivities: nil
        )
        
        // For iPad
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = exportButton
            popoverController.sourceRect = exportButton.bounds
        }
        
        present(activityViewController, animated: true)
    }
}

// AppDelegate and SceneDelegate
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
    }
}
