# The data of a form whose submission asks first, in typle-r's AlertDialog (layouts/application/_confirm_dialog).
module ConfirmHelper
  # A deletion as typle-r's DeleteConfirmation words it: the description is followed by "この操作は取り消せません。"
  def delete_confirm_data(title:, description:, details: nil, action: nil)
    confirm_data(title:, description: tt("common.delete.description", description:), details:, action:)
  end

  # typle-r's DeleteListDialog with its DeleteDetails: what the list holds, and its CSV export to keep the words.
  def list_delete_confirm_data(list, records)
    description = [records.any? ? tt("wordLists.delete.withRecords") : tt("wordLists.delete.listOnly"),
                   (tt("wordLists.delete.lastInPack", name: list.pack.name) if list.pack.word_lists.size == 1)].compact.join(" ")
    last = records.map(&:practiced_at).max
    contents = [tt("wordLists.delete.wordCount", count: list.words.size),
                last ? tt("wordLists.delete.records", count: records.size, day: records_day(last)) : tt("wordLists.delete.noRecords")].join(" · ")
    details = tag.div(class: "space-y-3") do
      safe_join([
        tag.dl(class: "grid gap-1 rounded-lg border bg-muted/40 px-3.5 py-3 text-sm") do
          safe_join([tag.dt(tt("wordLists.delete.list"), class: "sr-only"), tag.dd(list.name, class: "font-medium [overflow-wrap:anywhere]"),
                     tag.dt(tt("wordLists.delete.contents"), class: "sr-only"), tag.dd(contents, class: "text-[13px] text-muted-foreground tabular-nums")])
        end,
        tag.div(class: "flex flex-wrap items-center gap-x-3 gap-y-2 text-[13px] text-muted-foreground") do
          safe_join([tag.span(tt("wordLists.delete.exportHint"), class: "min-w-0 flex-1 basis-56"),
                     link_to(safe_join([icon(:download), tt("wordLists.delete.export")]), export_word_list_path(list),
                       class: button_classes(variant: :outline, size: :lg, class: "text-foreground"), data: { turbo: false })])
        end
      ])
    end
    delete_confirm_data(title: tt("wordLists.delete.title", name: list.name), description:, details:)
  end

  # typle-r's UnfollowDialog.
  def unfollow_confirm_data(name)
    delete_confirm_data(title: tt("wordLists.follow.title", name:), description: tt("wordLists.follow.description", name:), action: tt("wordLists.follow.confirm"))
  end

  def confirm_data(title:, description: nil, details: nil, action: nil, cancel: nil, variant: :destructive)
    { turbo_confirm: title, confirm_description: description, confirm_details: details&.to_str, confirm_action: action,
      confirm_cancel: cancel, confirm_variant: variant }.compact
  end
end
