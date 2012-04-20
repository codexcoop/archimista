// -------------------------------------------------------------------
// markItUp!
// -------------------------------------------------------------------
// Copyright (C) 2008 Jay Salvat
// http://markitup.jaysalvat.com/
// -------------------------------------------------------------------
// Textile tags example
// http://en.wikipedia.org/wiki/Textile_(markup_language)
// http://www.textism.com/
// -------------------------------------------------------------------
// Feel free to add more tags
// -------------------------------------------------------------------

// {name:'Heading', key:'1', openWith:'h1(!(([![Class]!]))!). ', placeHolder:'Your title here...' },
// {name:'Link', openWith:'"', closeWith:'([![Title]!])":[![Link:!:http://]!]', placeHolder:'Your text to link here...' }   

mySettings = {
  id: '',
  nameSpace: '',
  root: '',
  previewInWindow: 'width=400, height=400, resizable=yes, scrollbars=yes',
  previewAutoRefresh: true,
  previewPosition: 'after',
  previewTemplatePath: '/javascripts/markitup/templates/preview.html',
  previewParserPath: '/parse_textile',
  previewParserVar: 'data',
  resizeHandle: true,
  beforeInsert: '',
  afterInsert: '',
  onEnter: {},
  onShiftEnter: {keepDefault:false, replaceWith:'\n\n'},
  onCtrlEnter: {},
  onTab: {},
  markupSet: [
    {name:'Grassetto', key:'B', closeWith:'*', openWith:'*'},
    {name:'Corsivo', key:'I', closeWith:'_', openWith:'_'},
    {separator:'-----' },
    {name:'Elenco puntato', openWith:'(!(* |!|*)!)'},
    {name:'Elenco numerato', openWith:'(!(# |!|#)!)'},
    {separator:'-----' },
    {name:'Anteprima', className:'preview', call:'preview'}
  ]
}