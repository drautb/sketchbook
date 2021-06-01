extends Control

onready var image_name = $V/V/H1/ImageName
onready var extracted_date = $V/V/H1/ExtractedDate
onready var modified_date = $V/V/H1/ModifiedDate
onready var gedcomx_date = $V/V/H1/GedcomxDate

onready var index_label = $V/V/H2/CurrentIndex
onready var total_label = $V/V/H2/TotalValue
onready var percent_label = $V/V/H2/Percent
onready var goto_field = $V/V/H2/GotoIndex

var filepath
var data
var index
var total


func _ready():
  $FileDialog.get_cancel().disabled = true
  $FileDialog.show_modal(true)


func _refresh_ui():
  image_name.text = data[index].image
  index_label.text = str(index + 1)
  percent_label.text = "(%d%%)" % int((index + 1) / float(total) * 100)
  extracted_date.text = data[index].text
  if "modified" in data[index].keys():
    modified_date.text = data[index].modified
  else:
    modified_date.text = data[index].text.strip_escapes()

  if "gedcomx" in data[index].keys():
    gedcomx_date.text = data[index].gedcomx
  else:
    gedcomx_date.text = ""


func _on_FileDialog_file_selected(path):
  filepath = path
  var file = File.new()
  file.open(filepath, file.READ)
  var text = file.get_as_text()
  data = JSON.parse(text).result
  file.close()
  index = 0
  total = data.size()
  total_label.text = str(total)
  _refresh_ui()


func _on_Previous_pressed():
  if index > 0:
    index -= 1
  _refresh_ui()


func _on_Save__Next_pressed():
  data[index].modified = modified_date.text
  if gedcomx_date.text != "":
    data[index].gedcomx = gedcomx_date.text

  var file = File.new()
  file.open(filepath, File.WRITE)
  file.store_string(to_json(data))
  file.close()
  _on_Next_pressed()


func _on_Next_pressed():
  if index < total - 1:
    index += 1
  _refresh_ui()


func _on_Translate_pressed():
  OS.shell_open("https://translate.google.com/?sl=pt&tl=en&text=%s&op=translate" % data[index].text)


func _on_Portal_pressed():
  var segments = data[index].image.split("_")
  OS.shell_open("http://portal.ace.records.service.dev.us-east-1.dev.fslocal.org/#/stuff-viewer?group=%s&image=%s&reference=int" % [segments[0], segments[1]])


func _on_GoButton_pressed():
  var new_index = int(goto_field.text)
  if new_index > 0 and new_index < total - 1:
    index = new_index
    _refresh_ui()

