# DXF Import Tools - SketchUp Plugin

![Plugin Version](https://img.shields.io/badge/version-2.0-blue.svg)
![SketchUp](https://img.shields.io/badge/SketchUp-2017%2B-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 📝 Descrição

O **DXF Import Tools** é um plugin avançado para SketchUp que facilita a importação e correção de arquivos DXF. O plugin automatiza o processo de criação de faces e ocultação de arestas, oferecendo uma interface intuitiva e configurações personalizáveis.

### 🚀 Principais Funcionalidades

- **Importação inteligente de DXF**: Importa arquivos DXF e aplica correções automaticamente
- **Correção de seleção**: Processa apenas os elementos selecionados no modelo
- **Configurações personalizáveis**: Interface para ajustar comportamento do plugin
- **Histórico de operações**: Registro detalhado de todas as ações realizadas
- **Interface moderna**: Diálogos HTML responsivos com barra de progresso
- **Backup automático**: Criação automática de backup antes das operações
- **Processamento em lotes**: Otimizado para modelos grandes
- **Relatórios detalhados**: Estatísticas completas de cada operação

## 🎯 Recursos Principais

### 1. Importar e Corrigir DXF
- Importa arquivos DXF automaticamente
- Cria faces a partir de linhas conectadas
- Oculta arestas conforme configuração
- Validação de arquivos (tamanho, formato)
- Barra de progresso em tempo real

### 2. Correção de Seleção
- Processa apenas elementos selecionados
- Suporte para grupos e componentes
- Ideal para correções pontuais
- Preserva resto do modelo intacto

### 3. Configurações Avançadas
- **Criar faces**: Ativa/desativa criação automática de faces
- **Ocultar arestas**: Controla ocultação de arestas após processamento
- **Backup automático**: Cria backup do modelo antes das operações
- **Tamanho do lote**: Ajusta performance para modelos grandes
- **Tolerância**: Define precisão para criação de faces
- **Limite de arquivo**: Controla tamanho máximo de DXF

### 4. Histórico e Relatórios
- Log detalhado de todas as operações
- Timestamps e estatísticas
- Exportação de relatórios
- Limpeza de histórico
- Análise de erros e avisos

## 🛠️ Instalação

### Método 1: Instalação Manual
1. Faça download dos arquivos do plugin
2. Copie a pasta `suavizar_arestas` para o diretório de plugins do SketchUp:
   - **Windows**: `C:\Users\[usuario]\AppData\Roaming\SketchUp\SketchUp [versão]\SketchUp\Plugins\`
   - **Mac**: `~/Library/Application Support/SketchUp [versão]/SketchUp/Plugins/`
3. Copie também o arquivo `suavizar_arestas.rb` para o mesmo diretório
4. Reinicie o SketchUp

### Método 2: Instalação via Extension Manager
1. Abra o SketchUp
2. Vá em **Janela** > **Gerenciador de Extensões**
3. Clique em **Instalar Extensão**
4. Selecione o arquivo `.rbz` do plugin
5. Confirme a instalação

## 🎮 Como Usar

### Primeira Utilização
1. Após instalar, o plugin aparecerá no menu **Plugins** > **DXF Import Tools**
2. Uma barra de ferramentas será exibida automaticamente
3. Na primeira execução, uma mensagem explicará as funcionalidades

### Importar Arquivo DXF
1. Clique no ícone **Importar DXF** na barra de ferramentas
2. Selecione o arquivo DXF desejado
3. O plugin importará e processará automaticamente
4. Acompanhe o progresso na barra de carregamento
5. Visualize o relatório final com estatísticas

### Corrigir Seleção
1. Selecione os elementos que deseja corrigir (grupos, componentes ou arestas)
2. Clique no ícone **Corrigir Seleção** ou use o menu de contexto
3. O plugin processará apenas os elementos selecionados

### Configurar Plugin
1. Clique no ícone **Configurações**
2. Ajuste as opções conforme necessário:
   - Criação automática de faces
   - Ocultação de arestas
   - Backup automático
   - Tamanho do lote de processamento
   - Tolerância para faces
3. Clique em **Salvar**

### Visualizar Histórico
1. Clique no ícone **Histórico**
2. Visualize todas as operações realizadas
3. Exporte relatórios se necessário
4. Limpe o histórico quando desejado

## ⚙️ Configurações Detalhadas

| Configuração | Descrição | Padrão |
|-------------|-----------|---------|
| **Criar Faces** | Gera automaticamente faces a partir de arestas conectadas | ✅ Ativado |
| **Ocultar Arestas** | Oculta arestas após o processamento | ✅ Ativado |
| **Criar Backup** | Salva backup do modelo antes das operações | ✅ Ativado |
| **Tamanho do Lote** | Número de entidades processadas por vez | 100 |
| **Tolerância** | Precisão para criação de faces (em unidades do modelo) | 0.01 |
| **Limite de Arquivo** | Tamanho máximo de DXF aceito | 50 MB |

## 🎨 Interface

### Barra de Ferramentas
O plugin adiciona uma barra de ferramentas com 4 botões principais:

1. **🔄 Importar DXF**: Importa e processa arquivo DXF
2. **✏️ Corrigir Seleção**: Corrige elementos selecionados
3. **⚙️ Configurações**: Abre painel de configurações
4. **📋 Histórico**: Visualiza histórico de operações

### Menu Principal
Acesse via **Plugins** > **DXF Import Tools**:
- Importar e arrumar DXF
- Corrigir seleção atual
- Processar modelo completo
- Configurações
- Ver histórico
- Exportar relatório

### Menu de Contexto
Quando há elementos selecionados, o menu de contexto (botão direito) oferece:
- **🔧 Corrigir DXF na Seleção**: Processa apenas os elementos selecionados

## 📊 Recursos Técnicos

### Performance
- Processamento em lotes para modelos grandes
- Otimização de memória
- Atualização progressiva da interface
- Validação de arquivos antes do processamento

### Segurança
- Backup automático antes de operações
- Validação de integridade de arquivos
- Tratamento robusto de erros
- Operações com histórico de desfazer

### Compatibilidade
- SketchUp 2017 ou superior
- Suporte a arquivos DXF padrão
- Compatível com Windows e Mac
- Funciona com modelos de qualquer tamanho

## 🐛 Solução de Problemas

### Problemas Comuns

**Plugin não aparece no menu**
- Verifique se os arquivos estão na pasta correta de plugins
- Reinicie o SketchUp
- Verifique se o SketchUp tem permissões de escrita na pasta

**Erro ao importar DXF**
- Verifique se o arquivo não está corrompido
- Confirme se o arquivo não excede o limite de tamanho
- Tente com um arquivo DXF menor para testar

**Performance lenta**
- Reduza o tamanho do lote nas configurações
- Feche outros programas para liberar memória
- Trabalhe com modelos menores quando possível

**Backup não é criado**
- Salve o modelo antes de usar o plugin
- Verifique permissões de escrita na pasta do modelo
- Ative a opção "Criar Backup" nas configurações

### Arquivos de Log
O plugin mantém logs em:
- **Histórico**: `plugins/suavizar_arestas/historico.txt`
- **Configurações**: `plugins/suavizar_arestas/config.json`

## 🤝 Contribuições

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

Se encontrar problemas ou tiver sugestões:
1. Verifique a seção de **Solução de Problemas**
2. Consulte o histórico do plugin para erros
3. Abra uma issue no repositório do projeto

## 📚 Changelog

### v2.0 (Atual)
- ✨ Interface HTML moderna e responsiva
- ✨ Sistema de configurações personalizáveis
- ✨ Histórico detalhado de operações
- ✨ Barra de progresso em tempo real
- ✨ Backup automático de modelos
- ✨ Processamento em lotes otimizado
- ✨ Validação robusta de arquivos
- ✨ Relatórios de operação detalhados
- ✨ Menu de contexto para seleções
- ✨ Suporte a internacionalização
- 🐛 Correções de estabilidade

### v1.0
- 🚀 Funcionalidade básica de importação DXF
- 🚀 Criação automática de faces
- 🚀 Ocultação de arestas

---

**Desenvolvido com ❤️ para a comunidade SketchUp**