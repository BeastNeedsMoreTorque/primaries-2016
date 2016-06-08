# Creates <div class="dot-group">s given certain input data.
#
# Changing code here? Copy those changes to assets/javascripts/dot-groups.js.
module DotGroupHelper
  DotsPerGroup = 25

  CandidateStateDotSet = RubyImmutableStruct.new(:candidate_id_or_nil, :state_code, :n_delegates)
  CandidateStateDotSubgroup = RubyImmutableStruct.new(:candidate_id_or_nil, :state_code, :n_dots)

  DotGroupsWithSubgroups = RubyImmutableStruct.new(:dot_groups) do
    def to_s
      dot_groups.map(&:to_s).join('|')
    end

    def to_html(subgroup_key)
      html = []

      for dot_group in @dot_groups
        html << '<div class="dot-group">'

        for dot_subgroup in dot_group.dot_subgroups
          # Add U+200B zero width space because Chrome 51 on Fedora 23 doesn't
          # wrap correctly otherwise. Assuming span1 has length 5 and span2 has
          # length 5, it should show:
          #
          #     **
          #     **
          #     **
          #     **
          #     **
          #
          # But it actually shows:
          #
          #     **
          #     **
          #     **
          #     *
          #     *
          #     *
          #     *
          #
          # This happens after every multiple-of-5 length span.
          html << "<span #{subgroup_key}=\"#{dot_subgroup.data}\">#{'•' * dot_subgroup.n_dots}</span>\u200B"
        end

        html << '</div>'
      end

      html.join('')
    end
  end

  DotGroupWithSubgroups = RubyImmutableStruct.new(:dot_subgroups) do
    def to_s
      dot_subgroups.map(&:to_s).join(' ')
    end
  end

  DotSubgroup = RubyImmutableStruct.new(:data, :n_dots) do
    def to_s
      "#{data}:#{n_dots}"
    end
  end

  module HtmlMethods
    def dot_groups(n_groups, html_in_each)
      dot_group(html_in_each) * n_groups
    end

    def dot_group(html)
      "<div class=\"dot-group\">#{html}</div>"
    end

    def dot_subgroup(class_name, html)
      "<div class=\"dot-subgroup #{class_name}\">#{html}</div>"
    end

    def dot_string(n_dots)
      if n_dots < 0
        '' # We're fiddling with stuff in dev mode
      else
        '•' * n_dots
      end
    end
  end

  SimpleDotGroups = RubyImmutableStruct.new(:n_dots) do
    include HtmlMethods

    def to_html
      ret = []

      if n_dots >= DotsPerGroup
        ret << dot_groups(n_dots / DotsPerGroup, dot_string(DotsPerGroup))
      end

      if (n_dots % DotsPerGroup) > 0
        ret << dot_group(dot_string(n_dots % DotsPerGroup))
      end

      ret.join('')
    end
  end

  # Turns a list of candidate_states into some DotGroups
  def candidate_states_to_dot_groups(candidate_states, include_method, method)
    dot_sets = candidate_states.select(&include_method).map do |candidate_state|
      CandidateStateDotSet.new(candidate_state.candidate_id, candidate_state.state_code, candidate_state.send(method))
    end

    candidate_state_dot_sets_to_dot_groups(dot_sets)
  end

  # For a given state, returns dot groups by candidate ID
  #
  # e.g.:
  #
  #   party_state = database.party_states.find!('Dem-IA')
  #   html = party_state_dot_groups(party_state, :n_delegates)
  def party_state_dot_groups(party_state, method)
    dot_subgroups = party_state.candidate_states.map do |candidate_state|
      DotSubgroup.new(candidate_state.candidate_slug, candidate_state.send(method))
    end

    dot_subgroups << DotSubgroup.new('none', party_state.send("#{method}_without_candidates"))

    group_dot_subgroups(dot_subgroups).to_html('data-candidate-slug')
  end

  def races_to_unassigned_dot_groups(races, include_method, method)
    dot_sets = races.select(&include_method).map do |race|
      CandidateStateDotSet.new(nil, race.state_code, race.send(method))
    end

    candidate_state_dot_sets_to_dot_groups(dot_sets)
  end

  def candidate_race_dot_groups(candidate_race, method)
    SimpleDotGroups.new(candidate_race.send(method))
  end

  def race_assigned_unassigned_delegates_dot_groups_html(race, method1, method2)
    group_dot_subgroups([
      DotSubgroup.new('with-candidates', race.send(method1)),
      DotSubgroup.new('without-candidates', race.send(method2))
    ]).to_html('class')
  end

  def race_simple_dot_groups(race)
    SimpleDotGroups.new(race.n_delegates)
  end

  # Turns an Array of DotSubgroups into an Array of DotGroupWithSubgroups
  #
  # For instance, this code:
  #
  #   encode_subgroups([ DotSubgroup.new('AL', 24), DotSubgroup('AR', 10) ])
  #
  # will be organized into buckets of 25 dots each, like this:
  #
  #   [
  #     DotGroupWithSubgroups([ DotSubgroup.new('AL', 24), DotSubgroup.new('AR', 1) ]),
  #     DotGroupWithSubgroups([ DotSubgroup.new('AR', 9) ])
  #   ]
  def group_dot_subgroups(dot_subgroups)
    out = []
    out_remaining = 0

    cur_group = nil

    for in_subgroup in dot_subgroups
      n = in_subgroup.n_dots

      while n > 0
        if out_remaining == 0
          out_remaining = DotsPerGroup
          cur_group = DotGroupWithSubgroups.new([])
          out << cur_group
        end

        out_subgroup = DotSubgroup.new(in_subgroup.data, [ out_remaining, n ].min)
        cur_group.dot_subgroups << out_subgroup
        out_remaining -= out_subgroup.n_dots
        n -= out_subgroup.n_dots
      end
    end

    DotGroupsWithSubgroups.new(out)
  end

  private

  def candidate_state_dot_sets_to_dot_groups(dot_sets)
    ret = []

    dot_group = DotGroupWithSubgroups.new([])
    dots_left_in_group = DotsPerGroup

    dot_sets.each do |dot_set|
      dots_left_in_state = dot_set.n_delegates

      while dots_left_in_state > 0
        dots_in_subgroup = [ dots_left_in_group, dots_left_in_state ].min

        if dots_in_subgroup == 0
          ret << dot_group
          dot_group = DotGroupWithSubgroups.new([])
          dots_left_in_group = DotsPerGroup
          # Loop again; dots_in_subgroup won't be 0
        else
          dot_group.dot_subgroups << CandidateStateDotSubgroup.new(dot_set.candidate_id_or_nil, dot_set.state_code, dots_in_subgroup)
          dots_left_in_group -= dots_in_subgroup
          dots_left_in_state -= dots_in_subgroup
        end
      end
    end

    if dot_group.dot_subgroups.length > 0
      ret << dot_group
    end

    ret
  end
end
