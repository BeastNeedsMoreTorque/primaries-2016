# Creates <div class="dot-group">s given certain input data.
#
# Changing code here? Copy those changes to assets/javascripts/dot-groups.js.
module DotGroupHelper
  DotsPerGroup = 25
  DotGroupWithSubgroups = RubyImmutableStruct.new(:dot_subgroups)
  CandidateStateDotSet = RubyImmutableStruct.new(:candidate_id_or_nil, :state_code, :n_delegates)
  CandidateStateDotSubgroup = RubyImmutableStruct.new(:candidate_id_or_nil, :state_code, :n_dots)
  DotGroupWithClasses = RubyImmutableStruct.new(:dot_subgroups)
  ClassNameDotSubgroup = RubyImmutableStruct.new(:class_name, :n_dots)

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

  BisectedDotGroups = RubyImmutableStruct.new(:class_name1, :n_dots1, :class_name2, :n_dots2) do
    include HtmlMethods

    def to_html
      ret = []

      # Handle full class-1 dot-groups
      if n_dots1 >= DotsPerGroup
        ret << dot_groups(n_dots1 / DotsPerGroup, dot_subgroup(class_name1, dot_string(DotsPerGroup)))
      end

      # Handle partial class-1 and class-2 dot-groups
      remainder = n_dots1 % DotsPerGroup
      partial_dots2 = n_dots2
      if remainder > 0
        html = dot_subgroup(class_name1, dot_string(remainder))

        if n_dots2 >= DotsPerGroup - remainder
          partial_dots2 -= (DotsPerGroup - remainder)
          html << dot_subgroup(class_name2, dot_string(DotsPerGroup - remainder))
        elsif n_dots2 != 0
          partial_dots2 = 0
          html << dot_subgroup(class_name2, dot_string(n_dots2))
        end

        ret << dot_group(html)
      end

      # Handle full and partial class-2 dot-groups
      if partial_dots2 >= DotsPerGroup
        ret << dot_groups(partial_dots2 / DotsPerGroup, dot_subgroup(class_name2, dot_string(DotsPerGroup)))
      end

      if (partial_dots2 % DotsPerGroup) > 0
        ret << dot_group(dot_subgroup(class_name2, dot_string(partial_dots2 % DotsPerGroup)))
      end

      ret.join('')
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

  def races_to_unassigned_dot_groups(races, include_method, method)
    dot_sets = races.select(&include_method).map do |race|
      CandidateStateDotSet.new(nil, race.state_code, race.send(method))
    end

    candidate_state_dot_sets_to_dot_groups(dot_sets)
  end

  def candidate_race_dot_groups(candidate_race, method)
    SimpleDotGroups.new(candidate_race.send(method))
  end

  def race_assigned_unassigned_delegates_dot_groups(race, method1, method2)
    BisectedDotGroups.new('with-candidates', race.send(method1), 'without-candidates', race.send(method2))
  end

  def race_simple_dot_groups(race)
    SimpleDotGroups.new(race.n_delegates)
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
