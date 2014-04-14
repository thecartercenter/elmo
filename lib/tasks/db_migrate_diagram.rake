# Builds the diagram pdf after db:migrate is called
Rake::Task['db:migrate'].enhance do
  # only do this in dev mode
  if (Rails.env == 'development') && (ENV['NO_DIAGRAM'].blank?  )
    # Save to the docs dir
    ENV['filename'] = "#{Rails.root}/docs/erd"
    Rake::Task['erd'].invoke
  end
end
