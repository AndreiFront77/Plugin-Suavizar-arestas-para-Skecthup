require 'sketchup.rb'
require 'json'

module SuavizarArestas
  extend self

  PLUGIN_DIR = File.expand_path(__dir__)

  # ===== ícones por botão (um arquivo por botão) =====
  ICON_DIR = File.join(PLUGIN_DIR, 'icons') # coloque os pngs aqui
  def icon_path(name)
    File.join(ICON_DIR, "#{name}.png")
  end

  LOG_FILE = File.join(PLUGIN_DIR, 'historico.txt')
  CONFIG_FILE = File.join(PLUGIN_DIR, 'config.json')
  
  # configurações padrão
  DEFAULT_CONFIG = {
    'criar_faces' => true,
    'ocultar_arestas' => true,
    'criar_backup' => true,
    'batch_size' => 100,
    'max_file_size' => 50 * 1024 * 1024, # 50mb
    'tolerancia_faces' => 0.01
  }.freeze
  
  # i18n
  module I18n
    TEXTS = {
      'pt' => {
        'loading' => 'carregando, por favor aguarde...',
        'processing' => 'processando entidades...',
        'success' => 'processo concluído com sucesso!',
        'error' => 'erro ao processar arquivo',
        'backup_created' => 'backup criado',
        'file_too_large' => 'arquivo muito grande',
        'invalid_file' => 'arquivo inválido',
        'no_selection' => 'nenhuma entidade selecionada',
        'import_error' => 'erro ao importar o arquivo dxf',
        'faces_created' => 'faces criadas',
        'edges_hidden' => 'arestas ocultadas'
      }
    }.freeze
    
    def self.t(key)
      TEXTS['pt'][key] || key
    end
  end

  # utilitários e validações
  def carregar_configuracao
    if File.exist?(CONFIG_FILE)
      begin
        config = JSON.parse(File.read(CONFIG_FILE))
        DEFAULT_CONFIG.merge(config)
      rescue
        DEFAULT_CONFIG.dup
      end
    else
      DEFAULT_CONFIG.dup
    end
  end
  
  def salvar_configuracao(config)
    begin
      File.write(CONFIG_FILE, JSON.pretty_generate(config))
    rescue => e
      puts "erro ao salvar configuração: #{e.message}"
    end
  end
  
  def salvar_historico(operacao, detalhes)
    begin
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      File.open(LOG_FILE, 'a') { |f| f.puts "#{timestamp}: #{operacao} - #{detalhes}" }
    rescue => e
      puts "erro ao salvar histórico: #{e.message}"
    end
  end
  
  def validar_arquivo_dxf(path)
    return false unless path && File.exist?(path)
    return false unless File.extname(path).downcase == '.dxf'
    return false if File.size(path) == 0
    
    config = carregar_configuracao
    if File.size(path) > config['max_file_size']
      UI.messagebox(I18n.t('file_too_large'))
      return false
    end
    true
  end
  
  def criar_backup_modelo
    return unless carregar_configuracao['criar_backup']
    model = Sketchup.active_model
    if model.path && !model.path.empty?
      backup_path = model.path.sub(/\.skp$/, "_backup_#{Time.now.strftime('%Y%m%d_%H%M%S')}.skp")
      begin
        model.save_copy(backup_path)
        salvar_historico('backup', "criado: #{backup_path}")
        return backup_path
      rescue => e
        puts "erro ao criar backup: #{e.message}"
      end
    end
    nil
  end

  # tela de configurações
  def mostrar_configuracoes
    config = carregar_configuracao
    
    dlg = UI::HtmlDialog.new(
      dialog_title: "configurações dxf import",
      preferences_key: "suavizar_arestas_config",
      scrollable: true,
      resizable: true,
      width: 500,
      height: 600,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; margin: 0; background-color: #f5f5f5; }
            .container { background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .form-group { margin-bottom: 15px; }
            label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
            input[type="checkbox"] { margin-right: 8px; }
            input[type="number"] { width: 100px; padding: 5px; border: 1px solid #ddd; border-radius: 4px; }
            .buttons { text-align: center; margin-top: 20px; }
            button { padding: 10px 20px; margin: 0 5px; border: none; border-radius: 4px; cursor: pointer; }
            .btn-primary { background-color: #007cba; color: white; }
            .btn-secondary { background-color: #6c757d; color: white; }
            .btn-primary:hover { background-color: #005a8b; }
            .btn-secondary:hover { background-color: #545b62; }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>configurações do plugin</h2>
            <div class="form-group">
              <label><input type="checkbox" id="criar_faces" #{config['criar_faces'] ? 'checked' : ''}>criar faces automaticamente</label>
            </div>
            <div class="form-group">
              <label><input type="checkbox" id="ocultar_arestas" #{config['ocultar_arestas'] ? 'checked' : ''}>ocultar arestas após processamento</label>
            </div>
            <div class="form-group">
              <label><input type="checkbox" id="criar_backup" #{config['criar_backup'] ? 'checked' : ''}>criar backup automático do modelo</label>
            </div>
            <div class="form-group">
              <label for="batch_size">tamanho do lote de processamento:</label>
              <input type="number" id="batch_size" value="#{config['batch_size']}" min="10" max="1000">
            </div>
            <div class="form-group">
              <label for="tolerancia_faces">tolerância para criação de faces:</label>
              <input type="number" id="tolerancia_faces" value="#{config['tolerancia_faces']}" min="0.001" max="1" step="0.001">
            </div>
            <div class="buttons">
              <button class="btn-primary" onclick="salvarConfig()">salvar</button>
              <button class="btn-secondary" onclick="fecharDialog()">cancelar</button>
              <button class="btn-secondary" onclick="restaurarPadrao()">restaurar padrão</button>
            </div>
          </div>
          <script>
            function salvarConfig() {
              const config = {
                criar_faces: document.getElementById('criar_faces').checked,
                ocultar_arestas: document.getElementById('ocultar_arestas').checked,
                criar_backup: document.getElementById('criar_backup').checked,
                batch_size: parseInt(document.getElementById('batch_size').value),
                tolerancia_faces: parseFloat(document.getElementById('tolerancia_faces').value),
                max_file_size: #{config['max_file_size']}
              };
              sketchup.salvar_configuracao(JSON.stringify(config));
            }
            function fecharDialog() { sketchup.fechar_dialog(); }
            function restaurarPadrao() {
              document.getElementById('criar_faces').checked = true;
              document.getElementById('ocultar_arestas').checked = true;
              document.getElementById('criar_backup').checked = true;
              document.getElementById('batch_size').value = 100;
              document.getElementById('tolerancia_faces').value = 0.01;
            }
          </script>
        </body>
      </html>
    HTML

    dlg.add_action_callback("salvar_configuracao") { |_, config_json|
      begin
        config = JSON.parse(config_json)
        salvar_configuracao(config)
        UI.messagebox("configurações salvas com sucesso!")
        dlg.close
      rescue => e
        UI.messagebox("erro ao salvar configurações: #{e.message}")
      end
    }
    dlg.add_action_callback("fechar_dialog") { |_| dlg.close }
    dlg.set_html(html)
    dlg.show
  end

  # tela de carregamento com progresso
  def mostrar_carregando_com_progresso
    dlg = UI::HtmlDialog.new(
      dialog_title: "processando...",
      preferences_key: "suavizar_arestas_loading",
      scrollable: false,
      resizable: false,
      width: 450,
      height: 300,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; display:flex; flex-direction:column; justify-content:center; align-items:center; height:100%; margin:0; background:linear-gradient(135deg,#667eea 0%,#764ba2 100%); color:white; }
            .container { text-align:center; background:rgba(255,255,255,0.1); padding:30px; border-radius:15px; backdrop-filter:blur(10px); }
            .spinner { border:4px solid rgba(255,255,255,0.3); border-top:4px solid #ffffff; border-radius:50%; width:50px; height:50px; animation:spin 1s linear infinite; margin:0 auto 20px; }
            .progress-container { width:300px; height:10px; background-color:rgba(255,255,255,0.3); border-radius:5px; margin:20px auto; overflow:hidden; }
            .progress-bar { height:100%; background:linear-gradient(90deg,#4CAF50,#45a049); width:0%; transition:width 0.3s ease; border-radius:5px; }
            .status-text { margin-top:10px; font-size:14px; opacity:0.9; }
            @keyframes spin { 0%{transform:rotate(0deg);} 100%{transform:rotate(360deg);} }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="spinner"></div>
            <p id="main-text">#{I18n.t('loading')}</p>
            <div class="progress-container"><div class="progress-bar" id="progress"></div></div>
            <div class="status-text" id="status">iniciando...</div>
          </div>
          <script>
            function atualizarProgresso(porcentagem, status) {
              document.getElementById('progress').style.width = porcentagem + '%';
              document.getElementById('status').textContent = status;
            }
            function definirTexto(texto) { document.getElementById('main-text').textContent = texto; }
          </script>
        </body>
      </html>
    HTML

    dlg.add_action_callback("atualizar_progresso") { |_, _dados| }
    dlg.set_html(html)
    dlg.show
    dlg
  end

  # tela de sucesso
  def mostrar_sucesso_detalhado(faces, arestas, tempo, erros = [])
    dlg = UI::HtmlDialog.new(
      dialog_title: "relatório de processamento",
      preferences_key: "suavizar_arestas_sucesso",
      scrollable: true,
      resizable: true,
      width: 500,
      height: 600,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    html = <<-HTML
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: Arial, sans-serif; padding:20px; margin:0; background:linear-gradient(135deg,#667eea 0%,#764ba2 100%); color:white; }
            .container { background:rgba(255,255,255,0.95); color:#333; padding:30px; border-radius:15px; box-shadow:0 10px 30px rgba(0,0,0,0.3); }
            .header { text-align:center; margin-bottom:30px; }
            .checkmark { font-size:64px; color:#28a745; margin-bottom:15px; text-shadow:2px 2px 4px rgba(0,0,0,0.1); }
            .stats { display:grid; grid-template-columns:1fr 1fr; gap:20px; margin:20px 0; }
            .stat-card { background:#f8f9fa; padding:15px; border-radius:8px; text-align:center; border-left:4px solid #007cba; }
            .stat-number { font-size:24px; font-weight:bold; color:#007cba; }
            .stat-label { color:#666; margin-top:5px; }
            .errors { margin-top:20px; padding:15px; background:#fff3cd; border:1px solid #ffeaa7; border-radius:8px; }
            .error-item { margin:5px 0; color:#856404; }
            .buttons { text-align:center; margin-top:30px; }
            .btn { padding:10px 20px; margin:0 5px; border:none; border-radius:5px; cursor:pointer; font-size:14px; }
            .btn-primary { background-color:#007cba; color:white; }
            .btn-secondary { background-color:#6c757d; color:white; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="checkmark">✅</div>
              <h2>#{I18n.t('success')}</h2>
              <p>operação concluída em #{tempo.round(2)} segundos</p>
            </div>
            <div class="stats">
              <div class="stat-card"><div class="stat-number">#{faces}</div><div class="stat-label">#{I18n.t('faces_created')}</div></div>
              <div class="stat-card"><div class="stat-number">#{arestas}</div><div class="stat-label">#{I18n.t('edges_hidden')}</div></div>
            </div>
            #{erros.any? ?
              "<div class='errors'><h4>⚠️ avisos (#{erros.length}):</h4>#{erros.take(10).map { |e| "<div class='error-item'>• #{e}</div>" }.join}#{erros.length > 10 ? "<div class='error-item'>... e mais #{erros.length - 10} avisos</div>" : ""}</div>" : ""
            }
            <div class="buttons">
              <button class="btn btn-primary" onclick="verHistorico()">ver histórico</button>
              <button class="btn btn-secondary" onclick="fecharDialog()">fechar</button>
            </div>
          </div>
          <script>
            function verHistorico(){ sketchup.ver_historico(); }
            function fecharDialog(){ window.close(); }
          </script>
        </body>
      </html>
    HTML

    dlg.add_action_callback("ver_historico") { |_| mostrar_historico; dlg.close }
    dlg.set_html(html)
    dlg.show
  end
  
  # visualizador de histórico
  def mostrar_historico
    return unless File.exist?(LOG_FILE)
    
    dlg = UI::HtmlDialog.new(
      dialog_title: "histórico de operações",
      preferences_key: "suavizar_arestas_historico",
      scrollable: true,
      resizable: true,
      width: 600,
      height: 500,
      style: UI::HtmlDialog::STYLE_DIALOG
    )
    
    linhas = File.readlines(LOG_FILE).last(50).reverse rescue []
    
    html = <<-HTML
      <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin:0; padding:20px; background-color:#f5f5f5; }
            .container { background:white; border-radius:8px; padding:20px; box-shadow:0 2px 10px rgba(0,0,0,0.1); }
            .log-entry { padding:10px; margin:5px 0; border-left:3px solid #007cba; background:#f8f9fa; border-radius:0 5px 5px 0; }
            .timestamp { font-size:12px; color:#666; font-weight:bold; }
            .operation { margin-top:5px; color:#333; }
            .buttons { text-align:center; margin-top:20px; }
            .btn { padding:8px 16px; margin:0 5px; border:none; border-radius:4px; cursor:pointer; }
            .btn-danger { background-color:#dc3545; color:white; }
            .btn-secondary { background-color:#6c757d; color:white; }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>📋 histórico de operações</h2>
            <div class="log-entries">
              #{linhas.map { |linha|
                parts = linha.strip.split(': ', 2)
                if parts.length == 2
                  "<div class='log-entry'><div class='timestamp'>#{parts[0]}</div><div class='operation'>#{parts[1]}</div></div>"
                else
                  "<div class='log-entry'><div class='operation'>#{linha.strip}</div></div>"
                end
              }.join}
            </div>
            <div class="buttons">
              <button class="btn btn-danger" onclick="limparHistorico()">limpar histórico</button>
              <button class="btn btn-secondary" onclick="window.close()">fechar</button>
            </div>
          </div>
          <script>
            function limparHistorico(){
              if(confirm('tem certeza que deseja limpar todo o histórico?')){
                sketchup.limpar_historico(); location.reload();
              }
            }
          </script>
        </body>
      </html>
    HTML
    
    dlg.add_action_callback("limpar_historico") do |_|
      begin
        File.delete(LOG_FILE) if File.exist?(LOG_FILE)
        UI.messagebox("histórico limpo com sucesso!")
      rescue => e
        UI.messagebox("erro ao limpar histórico: #{e.message}")
      end
    end
    
    dlg.set_html(html)
    dlg.show
  end

  # lógica principal
  def ocultar_arestas_configuravel(entities)
    config = carregar_configuracao
    return 0 unless config['ocultar_arestas']
    edges = entities.grep(Sketchup::Edge)
    edges.each { |edge| edge.hidden = true }
    edges.size
  end

  def criar_faces_com_log(entities)
    config = carregar_configuracao
    return [0, []] unless config['criar_faces']
    new_faces = 0
    errors = []
    edges = entities.grep(Sketchup::Edge)

    edges.each do |edge|
      next unless edge.valid?
      next unless edge.faces.empty?
      begin
        result = edge.find_faces
        new_faces += 1 if result
      rescue => e
        errors << "erro na aresta #{edge.entityID}: #{e.message}" if errors.length < 100
      end
    end
    [new_faces, errors]
  end
  
  def processar_entidades_em_lotes(entities)
    config = carregar_configuracao
    batch_size = config['batch_size']
    faces_criadas_total = 0
    arestas_ocultadas_total = 0
    erros_total = []
    
    entities.each_slice(batch_size) do |batch|
      faces_criadas, erros = criar_faces_com_log(batch)
      arestas_ocultadas = ocultar_arestas_configuravel(batch)
      faces_criadas_total += faces_criadas
      arestas_ocultadas_total += arestas_ocultadas
      erros_total.concat(erros)
      Sketchup.active_model.active_view.invalidate if batch_size > 50
    end
    [faces_criadas_total, arestas_ocultadas_total, erros_total]
  end

  def processar_entidades(entities)
    faces_criadas, erros = criar_faces_com_log(entities)
    arestas_ocultadas = ocultar_arestas_configuravel(entities)
    [faces_criadas, arestas_ocultadas, erros]
  end

  # importar dxf e processar
  def importar_e_processar
    path = UI.openpanel("selecionar arquivo dxf", "", "arquivos dxf|*.dxf||")
    return unless validar_arquivo_dxf(path)

    criar_backup_modelo
    loading_dialog = mostrar_carregando_com_progresso
    tempo_inicio = Time.now

    UI.start_timer(0.3, false) {
      begin
        model = Sketchup.active_model
        view = model.active_view
        model.start_operation('importar e corrigir dxf', true)

        loading_dialog.execute_script("atualizarProgresso(10, 'importando arquivo dxf...')")
        status = model.import(path)
        unless status
          loading_dialog.close
          UI.messagebox(I18n.t('import_error'))
          salvar_historico('erro', "falha ao importar: #{File.basename(path)}")
          return
        end

        loading_dialog.execute_script("atualizarProgresso(30, 'analisando entidades...')")

        faces_criadas_total = 0
        arestas_ocultadas_total = 0
        erros_total = []
        stack = [model.active_entities]
        total_entities = 0
        processed_entities = 0

        temp_stack = [model.active_entities]
        until temp_stack.empty?
          entities = temp_stack.pop
          total_entities += entities.length
          entities.grep(Sketchup::Group).each { |g| temp_stack.push(g.entities) }
          entities.grep(Sketchup::ComponentInstance).each { |c| temp_stack.push(c.definition.entities) }
        end

        loading_dialog.execute_script("atualizarProgresso(40, 'processando entidades...')")

        until stack.empty?
          entities = stack.pop
          entities.grep(Sketchup::Group).each { |g| stack.push(g.entities) }
          entities.grep(Sketchup::ComponentInstance).each { |c| stack.push(c.definition.entities) }

          faces_criadas, arestas_ocultadas, erros = processar_entidades(entities)
          faces_criadas_total += faces_criadas
          arestas_ocultadas_total += arestas_ocultadas
          erros_total.concat(erros)
          
          processed_entities += entities.length
          progresso = 40 + (processed_entities.to_f / total_entities * 50).to_i
          loading_dialog.execute_script("atualizarProgresso(#{progresso}, 'processadas #{processed_entities}/#{total_entities} entidades...')")
        end

        loading_dialog.execute_script("atualizarProgresso(95, 'finalizando...')")
        
        model.commit_operation
        view.invalidate
        
        tempo_total = Time.now - tempo_inicio
        loading_dialog.close
        
        detalhes = "#{File.basename(path)} - #{faces_criadas_total} faces, #{arestas_ocultadas_total} arestas"
        detalhes += ", #{erros_total.length} avisos" if erros_total.any?
        salvar_historico('importação', detalhes)
        
        mostrar_sucesso_detalhado(faces_criadas_total, arestas_ocultadas_total, tempo_total, erros_total)
        
      rescue => e
        loading_dialog.close
        model.abort_operation
        UI.messagebox("erro durante o processamento: #{e.message}")
        salvar_historico('erro', "exceção: #{e.message}")
      end
    }
  end

  # corrigir seleção
  def corrigir_selecao
    model = Sketchup.active_model
    selection = model.selection
    if selection.empty?
      UI.messagebox(I18n.t('no_selection') + ". selecione um grupo, componente ou arestas para corrigir.")
      return
    end

    loading_dialog = mostrar_carregando_com_progresso
    tempo_inicio = Time.now

    UI.start_timer(0.3, false) {
      begin
        model.start_operation('corrigir seleção dxf', true)
        loading_dialog.execute_script("atualizarProgresso(20, 'analisando seleção...')")

        faces_criadas_total = 0
        arestas_ocultadas_total = 0
        erros_total = []
        stack = []

        selection.each do |ent|
          if ent.is_a?(Sketchup::Group)
            stack << ent.entities
          elsif ent.is_a?(Sketchup::ComponentInstance)
            stack << ent.definition.entities
          elsif ent.is_a?(Sketchup::Edge) || ent.is_a?(Sketchup::Face)
            stack << selection
            break
          end
        end

        loading_dialog.execute_script("atualizarProgresso(40, 'processando entidades selecionadas...')")

        stack_size = stack.length
        processed_stacks = 0

        until stack.empty?
          entities = stack.pop
          entities.grep(Sketchup::Group).each { |g| stack.push(g.entities) }
          entities.grep(Sketchup::ComponentInstance).each { |c| stack.push(c.definition.entities) }

          faces_criadas, arestas_ocultadas, erros = processar_entidades(entities)
          faces_criadas_total += faces_criadas
          arestas_ocultadas_total += arestas_ocultadas
          erros_total.concat(erros)
          
          processed_stacks += 1
          progresso = 40 + (processed_stacks.to_f / [stack_size, 1].max * 50).to_i
          loading_dialog.execute_script("atualizarProgresso(#{progresso}, 'processando grupo #{processed_stacks}...')")
        end

        loading_dialog.execute_script("atualizarProgresso(95, 'finalizando...')")

        model.commit_operation
        tempo_total = Time.now - tempo_inicio
        loading_dialog.close
        
        detalhes = "seleção corrigida - #{faces_criadas_total} faces, #{arestas_ocultadas_total} arestas"
        detalhes += ", #{erros_total.length} avisos" if erros_total.any?
        salvar_historico('correção', detalhes)
        
        mostrar_sucesso_detalhado(faces_criadas_total, arestas_ocultadas_total, tempo_total, erros_total)
        
      rescue => e
        loading_dialog.close
        model.abort_operation
        UI.messagebox("erro durante o processamento: #{e.message}")
        salvar_historico('erro', "correção falhou: #{e.message}")
      end
    }
  end

  # processar modelo completo
  def processar_modelo_completo
    return unless UI.messagebox("deseja processar todo o modelo atual? esta operação pode demorar.", MB_YESNO) == IDYES
    
    loading_dialog = mostrar_carregando_com_progresso
    tempo_inicio = Time.now
    
    UI.start_timer(0.3, false) {
      begin
        model = Sketchup.active_model
        model.start_operation('processar modelo completo', true)
        
        loading_dialog.execute_script("atualizarProgresso(10, 'analisando modelo completo...')")
        
        faces_criadas_total, arestas_ocultadas_total, erros_total = processar_entidades_em_lotes(model.active_entities)
        
        loading_dialog.execute_script("atualizarProgresso(95, 'finalizando...')")
        
        model.commit_operation
        tempo_total = Time.now - tempo_inicio
        loading_dialog.close
        
        salvar_historico('modelo completo', "#{faces_criadas_total} faces, #{arestas_ocultadas_total} arestas")
        mostrar_sucesso_detalhado(faces_criadas_total, arestas_ocultadas_total, tempo_total, erros_total)
        
      rescue => e
        loading_dialog.close
        model.abort_operation
        UI.messagebox("erro: #{e.message}")
        salvar_historico('erro', "modelo completo falhou: #{e.message}")
      end
    }
  end
  
  def exportar_relatorio
    return unless File.exist?(LOG_FILE)
    path = UI.savepanel("salvar relatório", "", "relatorio_dxf_import.txt")
    return unless path
    
    begin
      conteudo = File.read(LOG_FILE)
      config = carregar_configuracao
      
      relatorio = <<-REPORT
===============================================
    RELATÓRIO DXF IMPORT TOOLS
===============================================
data de geração: #{Time.now.strftime('%d/%m/%Y %H:%M:%S')}

configurações atuais:
- criar faces: #{config['criar_faces'] ? 'sim' : 'não'}
- ocultar arestas: #{config['ocultar_arestas'] ? 'sim' : 'não'}
- criar backup: #{config['criar_backup'] ? 'sim' : 'não'}
- tamanho do lote: #{config['batch_size']}
- tolerância: #{config['tolerancia_faces']}

histórico de operações:
#{conteudo}

===============================================
      REPORT
      
      File.write(path, relatorio)
      UI.messagebox("relatório exportado com sucesso!")
    rescue => e
      UI.messagebox("erro ao exportar relatório: #{e.message}")
    end
  end
  
  def obter_estatisticas_modelo
    model = Sketchup.active_model
    stats = {
      faces: model.active_entities.grep(Sketchup::Face).length,
      edges: model.active_entities.grep(Sketchup::Edge).length,
      groups: model.active_entities.grep(Sketchup::Group).length,
      components: model.active_entities.grep(Sketchup::ComponentInstance).length
    }
    
    stack = [model.active_entities]
    until stack.empty?
      entities = stack.pop
      entities.grep(Sketchup::Group).each do |g|
        stack.push(g.entities)
        stats[:faces] += g.entities.grep(Sketchup::Face).length
        stats[:edges] += g.entities.grep(Sketchup::Edge).length
      end
      entities.grep(Sketchup::ComponentInstance).each do |c|
        stack.push(c.definition.entities)
        stats[:faces] += c.definition.entities.grep(Sketchup::Face).length
        stats[:edges] += c.definition.entities.grep(Sketchup::Edge).length
      end
    end
    stats
  end

  # menus e toolbar
  unless file_loaded?(__FILE__)
    menu_principal = UI.menu('Plugins').add_submenu('dxf import tools')
    menu_principal.add_item('🔄 importar e arrumar dxf') { importar_e_processar }
    menu_principal.add_item('✏️ corrigir seleção atual') { corrigir_selecao }
    menu_principal.add_item('🌐 processar modelo completo') { processar_modelo_completo }
    menu_principal.add_separator
    menu_principal.add_item('⚙️ configurações') { mostrar_configuracoes }
    menu_principal.add_item('📋 ver histórico') { mostrar_historico }
    menu_principal.add_item('📄 exportar relatório') { exportar_relatorio }
    
    UI.add_context_menu_handler do |menu|
      selection = Sketchup.active_model.selection
      unless selection.empty?
        has_processable = selection.any? { |ent| 
          ent.is_a?(Sketchup::Group) || 
          ent.is_a?(Sketchup::ComponentInstance) || 
          ent.is_a?(Sketchup::Edge)
        }
        if has_processable
          menu.add_separator
          menu.add_item('🔧 corrigir dxf na seleção') { corrigir_selecao }
        end
      end
    end

    toolbar = UI::Toolbar.new('dxf import tools')

    # 1) importar e corrigir dxf
    cmd_importar = UI::Command.new('importar dxf') { importar_e_processar }
    cmd_importar.tooltip = 'importar e corrigir arquivo dxf'
    cmd_importar.status_bar_text = 'importa um dxf e gera as faces automaticamente com configurações personalizadas.'
    cmd_importar.small_icon = icon_path('importar_corrigir_dxf')
    cmd_importar.large_icon = icon_path('importar_corrigir_dxf')
    toolbar.add_item(cmd_importar)

    # 2) corrigir seleção atual
    cmd_corrigir = UI::Command.new('corrigir seleção') { corrigir_selecao }
    cmd_corrigir.tooltip = 'corrigir a seleção atual'
    cmd_corrigir.status_bar_text = 'cria faces e oculta arestas da seleção atual conforme configurações.'
    cmd_corrigir.small_icon = icon_path('corrigir_selecao')
    cmd_corrigir.large_icon = icon_path('corrigir_selecao')
    toolbar.add_item(cmd_corrigir)
    
    toolbar.add_separator
    
    # 3) abrir configurações
    cmd_config = UI::Command.new('configurações') { mostrar_configuracoes }
    cmd_config.tooltip = 'abrir configurações do plugin'
    cmd_config.status_bar_text = 'personalizar comportamento do plugin dxf import.'
    cmd_config.small_icon = icon_path('configuracoes')
    cmd_config.large_icon = icon_path('configuracoes')
    toolbar.add_item(cmd_config)
    
    # 4) ver histórico
    cmd_historico = UI::Command.new('histórico') { mostrar_historico }
    cmd_historico.tooltip = 'ver histórico de operações'
    cmd_historico.status_bar_text = 'visualizar log de todas as operações realizadas.'
    cmd_historico.small_icon = icon_path('historico')
    cmd_historico.large_icon = icon_path('historico')
    toolbar.add_item(cmd_historico)

    toolbar.show
    
    carregar_configuracao
    salvar_historico('plugin', 'dxf import tools v2.0 carregado com sucesso')
    
    primeira_vez_file = File.join(PLUGIN_DIR, '.primeira_vez')
    unless File.exist?(primeira_vez_file)
      UI.messagebox("dxf import tools v2.0 carregado!\n\n✨ novas funcionalidades:\n• configurações personalizáveis\n• histórico de operações\n• melhor interface\n• tratamento de erros\n• barra de progresso\n\nacesse o menu 'plugins > dxf import tools' para começar!", MB_OK)
      File.write(primeira_vez_file, Time.now.to_s) rescue nil
    end
    
    file_loaded(__FILE__)
  end
end
