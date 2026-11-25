# The guide's colour legend: examples of a word being typed (GuideDesignHelper::GUIDE_LEGEND), each with its letters in
# the practice screen's colours and what each colour means.
class Guide::ColorLegendComponent < ApplicationComponent
  delegate :guide_t, :guide_rich, :guide_letter_states, to: :helpers

  private

  def examples = GuideDesignHelper::GUIDE_LEGEND

  # PracticeText with TargetText's letters. Built in one piece: the paragraph keeps its whitespace (pre-wrap), so none
  # may come between the letters.
  def letters(example)
    taken = example[:missed] ? example[:typed][0...-1] : example[:typed]
    states = guide_letter_states(example[:sample], taken, example[:missed])
    tag.p(class: "mx-auto my-0 w-4/5 max-h-[min(5lh,28dvh)] max-w-full overflow-y-auto overscroll-contain py-[0.25em] text-center font-medium whitespace-pre-wrap [overflow-wrap:anywhere] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden text-3xl leading-tight tracking-wide") do
      safe_join(states.map { |char, state| tag.span(char, class: GuideDesignHelper::GUIDE_LETTER.fetch(state), "data-state": state.to_s.tr("_", "-")) })
    end
  end

  def typed(example) = guide_rich(guide_t("legend.typed", typed: example[:typed]), { mono: ->(inner) { tag.span(inner, class: "font-mono") } })

  def swatch_class(state) = cn("font-medium", GuideDesignHelper::GUIDE_SWATCH.fetch(state))
end
