module WorkReportsHelper
  def format_days(days)
    l(:text_days_plural, :count => h(days.to_f))
  end
end
