all:
	zip -u game.zip 'index.js' 'index.html'

publish:
	butler push game.zip purdy/2024-fall-game-jam:html
