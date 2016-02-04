require 'date'

# A Sparkline is an Array of 180 FLoats, one for each of the past 180 days.
#
# The last day is today.
class Sparkline
  NDates = 180

  def initialize(last_day_mjd=nil)
    @last_day = last_day_mjd || Date.today.mjd # Julian day number, an Integer
    @day0 = @last_day - NDates + 1
    @values = [nil] * NDates
  end

  def add_value(date_mjd, float)
    index = date_mjd - @day0
    return if index < 0 || index >= NDates
    @values[index] = float
  end

  def empty?
    @values.compact.empty?
  end

  def min
    @values.compact.min
  end

  def max
    @values.compact.max
  end

  def range
    return nil if max.nil?

    [ [ 0, min - 1 ].max, [ 100, max + 1 ].min ]
  end

  def to_svg
    [
      "<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 180 60\">",
      "  <path d=\"#{to_svg_path}\"/>",
      "</svg>"
    ].join
  end

  def to_svg_path
    # x(index) = index
    # y(value) = 60 - (value - y_min) * y_factor
    y_min = range[0]
    y_factor = 60.to_f / (range[1] - range[0])

    parts = []

    last_y = nil

    @values.each_with_index do |value, index|
      next if value.nil?

      x = index
      y = (60 - (value - y_min) * y_factor).to_i

      if last_y.nil?
        parts << "M#{x},#{y}"
      else
        parts << "H#{x}"

        if y != last_y
          parts << "V#{y}"
        end
      end

      last_y = y
    end

    parts.join
  end
end
