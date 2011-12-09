# $("""
#     <script id="uploader_tpl" type="text/template">
#         <div class="uploader-head">
#             {% trans 'Uploader' %}
#             <a class="control iconic fullscreen" title="{% trans 'Expand uploader' %}" data-alttitle="{% trans 'Minimize uploader' %}"></a>
#         </div>
#         <div class="uploader-controls breadcrumbs">
#             <form class="selector">
#                 <input type="file" multiple>
#                 <a class="iconic plus" href="#"> {% trans 'Add files' %}</a>
#             </form>
#             <form class="selector directory">
#                 <input type="file"  webkitdirectory directory mozdirectory>
#                 <a class="iconic plus" href="#"> {% trans 'Add folder (experimental)' %}</a>
#             </form>
#             <a class="iconic trash finished" href="#"> {% trans 'Clear finished' %}</a>
#             <a class="iconic trash rqueued" href="#"> {% trans 'Remove queued' %}</a>
#         </div>
#         <div class="uploader-table-container">
#             <div class="uploader-table">
#             </div>
#         </div>
#     </script>


#     <script id="file_upload_tpl" type="text/template">
#         <div class="file">
#             <div class="status"></div>
#             <a class="abort iconic x" title="{% trans 'Cancel this upload' %}"></a>
#             <%= filename %>
#             <span class="indicators">
#                 (<span class="percent">0</span>% @ <span class="speed">0 B/s</span>)
#             </span>
#             <span class="failed">({% trans 'Failed' %})</span>
#             <span class="aborted">({% trans 'Aborted' %})</span>
#         </div>
#     </script>
# """).appendTo('head')

FileUploader.init()
FileUploader.do_browse('')