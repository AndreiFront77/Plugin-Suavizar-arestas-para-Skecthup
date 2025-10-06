# loader do plugin suavizar_arestas
require 'sketchup.rb'

plugin_dir = File.join(File.dirname(__FILE__), 'suavizar_arestas')
main_file  = File.join(plugin_dir, 'suavizar_arestas.rb')

if File.exist?(main_file)
  load main_file
else
  UI.messagebox("não encontrei o arquivo principal do plugin:\n#{main_file}")
end
