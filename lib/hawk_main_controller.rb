require 'jrubyfx'
require 'jrubyfx-fxmlloader'
require 'hawkular/hawkular_client'

require_relative 'hawk_helper'
require_relative 'h_tree_item'
require_relative 'alert_controller'
require_relative 'event_insert_controller'
require_relative 'insert_metrics_controller'
require_relative 'on_click_cell_factory'
require_relative 'metrics_only_cell_factory'
require_relative 'time_picker'
require_relative 'chart_view_controller'

class HawkMainController
  include JRubyFX::Controller
  fxml 'fxmain.fxml'


  def show_initial_tree(mode= :hawkular, tenant )
    # First load the chart custom control
    chart_anchor = @FXMLtreeView.scene.lookup('#FXMLChartAnchor')
    chart_anchor.children.add chart_view_controller # TODO rename back to chart_view?

    # Then load the time picker custom control
    # This needs to go after the chart as it will immediately call back
    hbox = @FXMLtreeView.scene.lookup('#FXMLTopBox')
    hbox.children.add time_picker(self, :set_time_range)

    if mode == :hawkular
      @FXMLtreeView.setCellFactory proc { ::OnClickCellFactory.new }
      show_initial_tree_with_feeds
    else # :metrics
      @FXMLtreeView.setCellFactory proc { ::MetricsOnlyCellFactory.new }
      # @FXMLalertMenu.setEnabled false #TODO
      # @FXMLreloadFeeds.setEnabled false #TODO
      list_metrics
    end
  end

  def show_initial_tree_with_feeds
    tree_root = tree_item('Feeds')
    feeds = $inventory_client.list_feeds
    feeds.each do |feed|
      iv = ::HawkHelper.create_icon 'F'

      new_feed = build(::HTreeItem)
      new_feed.kind = :feed
      new_feed.value = feed
      new_feed.graphic = iv

      tree_root.children.add new_feed
      puts new_feed.to_s
    end
    # bind to the view from fxml
    @FXMLtreeView.setRoot(tree_root)
    tree_root.expanded=true
  end

  # Load the alerts window
  def show_alerts
    popup_stage = Stage.new
    ::AlertController.load_into popup_stage
    popup_stage.title='Alerts & Definitions'
    popup_stage.init_modality=:none
    popup_stage.init_owner(@FXMLtreeView.scene.window)
    popup_stage.show
  end

  # List metrics for a metrics only target
  def list_metrics
    gauges = $metric_client.gauges.query
    counters = $metric_client.counters.query

    tree_root = tree_item('Metrics')
    metrics = gauges.concat counters

    metrics.each do |metric_def|
      iv = ::HawkHelper.create_icon 'M'

      new_metric = build(::HTreeItem)
      new_metric.kind = :metric
      new_metric.value = metric_def.id
      new_metric.graphic = iv

      # Create a Metric type of Inventory
      # from the metric dev obtained from H-Metrics
      m_hash = {
          'name' => metric_def.id,
          'id' => metric_def.id,
          'type' => { 'type' => metric_def.json['type'].upcase},
          # :unit => metric_def.unit
      }
      m = ::Hawkular::Inventory::Metric.new m_hash

      new_metric.metric = m

      tree_root.children.add new_metric
    end
    # bind to the view from fxml
    @FXMLtreeView.setRoot(tree_root)
    tree_root.expanded=true

  end

  def show_insert_metrics
    popup_stage = Stage.new
    ::InsertMetricsController.load_into popup_stage
    popup_stage.title='Insert Metrics'
    popup_stage.init_modality=:none
    popup_stage.init_owner(@FXMLtreeView.scene.window)
    popup_stage.show
  end

  def show_insert_events
    popup_stage = Stage.new
    ::EventInsertController.load_into popup_stage
    popup_stage.title='Insert Events'
    popup_stage.init_modality=:none
    popup_stage.init_owner(@FXMLtreeView.scene.window)
    popup_stage.show
  end

  def reload_feeds
    show_initial_tree_with_feeds
  end

  # Callback from time picker
  def set_time_range(time_in_ms)
    cv = find('#myChartView')
    cv.change_time time_in_ms
  end
end