class ArticleExporter

  @@csv_options = { col_sep: ";",  encoding: 'utf-8'}

  def self.export( csv, user, params = nil )

    # Generate proper headers and find out if we are messing with transactions
    export_attributes = MassUpload.article_attributes

    #write the headers and set options for csv generation
    csv.puts CSV.generate_line export_attributes, @@csv_options


    determine_articles_to_export( user, params ).find_each do |article|

      row = Hash.new
      row.merge!(provide_fair_attributes_for article)
      row.merge!(article.attributes)
      row["categories"] = article.categories.map { |c| c.id }.join(",")
      row["external_title_image_url"] = article.images.first.external_url if article.images.first
      row["image_2_url"] = article.images[1].external_url if article.images[1]
      csv.puts CSV.generate_line export_attributes.map { |element| row[element] }, @@csv_options

    end
    csv.flush
  end


  def self.export_erroneous_articles erroneous_articles
    csv = CSV.generate_line( MassUpload.article_attributes, @@csv_options )
    erroneous_articles.each do |article|
      csv += article.article_csv
    end
    csv
  end


  def self.determine_articles_to_export user, params
    if params == "active"
      user.articles.where(:state => "active").order("created_at ASC").includes(:images,:categories,:social_producer_questionnaire,:fair_trust_questionnaire)
    elsif params == "inactive"
      user.articles.where("state = ? OR state = ?","preview","locked").order("created_at ASC").includes(:images,:categories,:social_producer_questionnaire,:fair_trust_questionnaire)
    end
  end


  def self.provide_fair_attributes_for article
    attributes = Hash.new
    if article.fair_trust_questionnaire
      attributes.merge!(article.fair_trust_questionnaire.attributes)
    end

    if article.social_producer_questionnaire
      attributes.merge!(article.social_producer_questionnaire.attributes)
    end
    serialize_checkboxes_in attributes
  end


  def self.serialize_checkboxes_in attributes
    attributes.each do |k, v|
      if k.include?("checkboxes")
        if v.any?
          attributes[k] = v.join(',')
        else
          attributes[k] = nil
        end
      end
    end
    attributes
  end

  # methods for exporting line_item_group articles with corresponding fields of
  # line_item_group, business_transaction
  def self.export_line_item_groups(csv, user, params)
    csv.puts(CSV.generate_line(export_attrs, @@csv_options))

    get_line_item_groups(user, params).find_each do |lig|
      lig.business_transactions.find_each do |bt|
        row = Hash.new
        [lig, bt, bt.article].each do |item|
          attrs = Hash[item.attributes.map {|k, v| [export_mappings(item)[k], v] }]
          row.merge!(attrs.select { |k, v| export_attrs.include?(k) })
        end
        csv.puts(CSV.generate_line(export_attrs.map { |element| row[element] }, @@csv_options))
      end
    end
    csv.flush
  end

  def self.get_line_item_groups(user, params)
    if params[:time_range] && params[:time_range] != 'all'
      user.seller_line_item_groups.where('created_at > ? AND created_at < ?', params[:time_range].to_i.month.ago, Time.now).includes(:buyer, business_transactions: [:article])
    else
      user.seller_line_item_groups
    end
  end

  # Maps attributes of a model to attribute name prefixed with model name
  def self.export_mappings(item)
    hash = {}
    item.class.column_names.each { |column_name| hash[column_name] = "#{mapping_name[item.class.name]}_#{column_name}"}
    return hash
  end

  # used to prefix model attributes in csv with user friendly name instead of model name
  def self.mapping_name
    {
      'Article' => 'article',
      'BusinessTransaction' => 'transaction',
      'LineItemGroup' => 'purchase',
      'User' => 'buyer',
      'Address' => 'address'
    }
  end

  # used to determine which columns of line_item_groups and business_transactions and articles should be exported
  # TODO consider which attributes should be exported and write them to the array
  def self.export_attrs
    [
      'purchase_id', 'purchase_created_at', 'transaction_id',
      'transaction_quantity_bought', 'article_id', 'article_title',
      'article_custom_seller_identifier'
    ]
  end


end
