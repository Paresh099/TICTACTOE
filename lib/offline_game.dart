import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Game history model
class GameHistory {
  final String winner;
  final DateTime timestamp;
  final List<String> finalBoard;
  final int gameNumber;

  GameHistory({
    required this.winner,
    required this.timestamp,
    required this.finalBoard,
    required this.gameNumber,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'winner': winner,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'finalBoard': finalBoard,
      'gameNumber': gameNumber,
    };
  }

  // Create from JSON
  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      winner: json['winner'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      finalBoard: List<String>.from(json['finalBoard']),
      gameNumber: json['gameNumber'],
    );
  }
}

class OfflineGame extends StatefulWidget {
  @override
  _OfflineGameState createState() => _OfflineGameState();
}

class _OfflineGameState extends State<OfflineGame>
    with TickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  String winner = '';
  bool gameOver = false;
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  int gameCount = 0;
  List<GameHistory> gameHistory = [];
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // Load saved data when app starts
    _loadGameData();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // Load game data from SharedPreferences
  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      xWins = prefs.getInt('xWins') ?? 0;
      oWins = prefs.getInt('oWins') ?? 0;
      draws = prefs.getInt('draws') ?? 0;
      gameCount = prefs.getInt('gameCount') ?? 0;
    });

    // Load game history
    final historyJson = prefs.getStringList('gameHistory') ?? [];
    setState(() {
      gameHistory = historyJson
          .map((json) => GameHistory.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  // Save game data to SharedPreferences
  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('xWins', xWins);
    await prefs.setInt('oWins', oWins);
    await prefs.setInt('draws', draws);
    await prefs.setInt('gameCount', gameCount);

    // Save game history as JSON strings
    final historyJson = gameHistory
        .map((game) => jsonEncode(game.toJson()))
        .toList();
    await prefs.setStringList('gameHistory', historyJson);
  }

  void _makeMove(int index) {
    if (board[index] == '' && !gameOver) {
      setState(() {
        board[index] = isXTurn ? 'X' : 'O';
        isXTurn = !isXTurn;
      });
      _scaleController.forward().then((_) => _scaleController.reverse());
      _checkWinner();
    }
  }

  void _checkWinner() {
    // Winning combinations
    List<List<int>> winningCombinations = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (List<int> combination in winningCombinations) {
      if (board[combination[0]] != '' &&
          board[combination[0]] == board[combination[1]] &&
          board[combination[1]] == board[combination[2]]) {
        setState(() {
          winner = board[combination[0]];
          gameOver = true;
          if (winner == 'X') {
            xWins++;
          } else {
            oWins++;
          }
          _addGameToHistory();
        });
        _bounceController.forward();
        return;
      }
    }

    // Check for draw
    if (!board.contains('')) {
      setState(() {
        winner = 'Draw';
        gameOver = true;
        draws++;
        _addGameToHistory();
      });
      _bounceController.forward();
    }
  }

  void _addGameToHistory() {
    gameCount++;
    gameHistory.insert(0, GameHistory(
      winner: winner,
      timestamp: DateTime.now(),
      finalBoard: List.from(board),
      gameNumber: gameCount,
    ));

    // Save data after each game
    _saveGameData();
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      isXTurn = true;
      winner = '';
      gameOver = false;
    });
    _bounceController.reset();
  }

  Future<void> _resetScore() async {
    setState(() {
      xWins = 0;
      oWins = 0;
      draws = 0;
      gameCount = 0;
      gameHistory.clear();
    });
    _resetGame();

    // Clear saved data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('xWins');
    await prefs.remove('oWins');
    await prefs.remove('draws');
    await prefs.remove('gameCount');
    await prefs.remove('gameHistory');
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryModal(gameHistory: gameHistory),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCell(int index) {
    return GestureDetector(
      onTap: () => _makeMove(index),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                board[index],
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: board[index] == 'X' ? Colors.blue : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Back Button and History Button
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'OFFLINE GAME',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            gameOver
                                ? 'Game Over'
                                : isXTurn ? "Player X's Turn" : "Player O's Turn",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showHistory,
                      icon: Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Score Board
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreCard('X', xWins, Colors.blue),
                    _buildScoreCard('DRAW', draws, Colors.orange),
                    _buildScoreCard('O', oWins, Colors.red),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Game Board
              Expanded(
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildGameCell(0)),
                                  SizedBox(width: 10),
                                  Expanded(child: _buildGameCell(1)),
                                  SizedBox(width: 10),
                                  Expanded(child: _buildGameCell(2)),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildGameCell(3)),
                                  SizedBox(width: 10),
                                  Expanded(child: _buildGameCell(4)),
                                  SizedBox(width: 10),
                                  Expanded(child: _buildGameCell(5)),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildGameCell(6)),
                                  SizedBox(width: 10),
                                  Expanded(child: _buildGameCell(7)),
                                  SizedBox(width: 10),
                                  Expanded(child: _buildGameCell(8)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Winner Display
              if (gameOver)
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bounceAnimation.value,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: winner == 'Draw'
                              ? Colors.orange.withOpacity(0.9)
                              : winner == 'X'
                              ? Colors.blue.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          winner == 'Draw' ? 'It\'s a Draw!' : 'Player $winner Wins!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

              SizedBox(height: 20),

              // Control Buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'New Game',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetScore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.7),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'Reset Score',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// History Modal Component
class HistoryModal extends StatelessWidget {
  final List<GameHistory> gameHistory;

  const HistoryModal({Key? key, required this.gameHistory}) : super(key: key);

  Widget _buildMiniBoard(List<String> board) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMiniCell(board[0])),
                  Container(width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildMiniCell(board[1])),
                  Container(width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildMiniCell(board[2])),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.3)),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMiniCell(board[3])),
                  Container(width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildMiniCell(board[4])),
                  Container(width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildMiniCell(board[5])),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.3)),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMiniCell(board[6])),
                  Container(width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildMiniCell(board[7])),
                  Container(width: 1, color: Colors.white.withOpacity(0.3)),
                  Expanded(child: _buildMiniCell(board[8])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCell(String value) {
    return Container(
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: value == 'X' ? Colors.blue : Colors.red,
          ),
        ),
      ),
    );
  }

  Color _getWinnerColor(String winner) {
    switch (winner) {
      case 'X':
        return Colors.blue;
      case 'O':
        return Colors.red;
      case 'Draw':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${date.day} ${months[date.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade800,
            Colors.deepPurple.shade400,
            Colors.pink.shade300,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.white, size: 28),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'Game History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Stats Summary
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Total Games', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${gameHistory.length}', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('X Wins', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${gameHistory.where((g) => g.winner == 'X').length}', style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('O Wins', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${gameHistory.where((g) => g.winner == 'O').length}', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('Draws', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${gameHistory.where((g) => g.winner == 'Draw').length}', style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // History List
          Expanded(
            child: gameHistory.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.white.withOpacity(0.3)),
                  SizedBox(height: 16),
                  Text(
                    'No games played yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Start playing to see your game history!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: gameHistory.length,
              itemBuilder: (context, index) {
                final game = gameHistory[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getWinnerColor(game.winner).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Game number and result
                      Container(
                        width: 60,
                        child: Column(
                          children: [
                            Text(
                              '#${game.gameNumber}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getWinnerColor(game.winner).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                game.winner == 'Draw' ? 'DRAW' : '${game.winner} WIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 16),

                      // Mini board
                      _buildMiniBoard(game.finalBoard),

                      SizedBox(width: 16),

                      // Time and date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDate(game.timestamp),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatTime(game.timestamp),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}