ActionController::Routing::Routes.draw do |map|

  map.devise_for :users, :path_names => { :sign_in => 'login', :sign_out => 'logout' }
  map.resources :users, :member => { :toggle_active => :put }
  map.resources :groups

  # Polymorphic resources (must be here, prior to parent resources)
  map.resources :digital_objects, :only => [:destroy], :collection => { :all => :get, :disabled => :get }

  # Schede
  map.resources :fonds, :except => [:new],
    :member => {
      :tree             => :get,
      :treeview         => :get,
      :ajax_update      => :put,
      :rename           => :put,
      :move             => :put,
      :merge_with       => :get,
      :merge            => :post,
      :trash            => :get,
      :trashed_subtree  => :get,
      :move_to_trash    => :put,
      :restore_subtree  => :put,
      :destroy_subtree  => :delete
  },
    :collection => {
      :save_a_tree      => :get,
      :saving_the_tree  => :post,
      :list             => :get,
      :ajax_create      => :post
  } do |fonds|
    fonds.resources :units,
      :collection   => {
        :gridview     => [:get, :post],
        :grid         => :get,
        :add_rows     => :post,
        :remove_rows  => :put,
        :reorder_rows => :put,
        :new_iccd => :get
    }
    fonds.resources :digital_objects, :except => [:show, :destroy]
  end

  map.resources :units, :except => [:new],
    :member => {
      :ajax_update      => :put,
      :render_full_path => :get,
      :preferred_event  => :get,
      :textfield_form   => :get,
      :update_event     => :put,
      :edit_iccd        => :get,
      :show_iccd        => :get
  },
    :collection => {
      :list_oa_mtc      => :get,
      :list_oa_ogtd     => :get,
      :list_bdm_ogtd    => :get,
      :list_bdm_mtcm    => :get,
      :list_bdm_mtct    => :get,
      :classify         => :put
  } do |units|
    units.resources :children, :controller => 'units', # OPTIMIZE: rinominare in subunits ?
    :collection   => { :new_iccd => :get }
    units.resources :digital_objects, :except => [:show, :destroy]
  end

  map.resources :creators, :collection => { :list => :get } do |creators|
    creators.resources :digital_objects, :except => [:show, :destroy]
  end

  map.resources :custodians, :collection => { :list => :get } do |custodians|
    custodians.resources :digital_objects, :except => [:show, :destroy]
  end

  map.resources :sources, :collection => { :list => :get } do |sources|
    sources.resources :digital_objects, :except => [:show, :destroy]
  end

  map.resources :institutions, :collection => { :list => :get }
  map.resources :document_forms, :collection => { :list => :get }
  map.resources :projects, :collection => { :list => :get }

  map.resources :editors,
    :collection => {
      :list         => :get,
      :modal_new     => :get,
      :modal_create  => :post
  }

  # Strumenti
  map.resources :headings,
    :collection => {
      :import_csv   => :get,
      :preview_csv  => :post,
      :save_csv     => :post,
      :list         => :get,
      :modal_new    => :get,
      :modal_create => :post,
      :modal_link   => :get,
      :ajax_list    => :get,
      :ajax_remove  => :post,
      :ajax_link    => :post
  }

  map.resources :reports, :only => [:index],
    :member => {
      :dashboard                  => :get,
      :summary                    => :get,
      :inventory                  => :get,
      :creators                   => :get,
      :custodians                 => :get,
      :labels                     => :get,
      :units_by_reference_number  => :get, # OPTIMIZE: forse possibile unificare azione con diverso parametro get
      :units_by_sequence_number   => :get,
  }

  map.resources :quality_checks, :only => [:index],
    :member => {
      :fond           => :get,
      :creator        => :get,
      :custodian      => :get,
  }

  map.resources :imports, :only => [:index, :new, :create, :destroy]
  map.resources :exports, :only => [:index],
    :collection => {
      :download => :get,
    }

  # Vocabolari
  map.resources :vocabularies, :only => [:index]

  map.resources :creator_corporate_types, :only => [:index]
  map.resources :custodian_types, :only => [:index]
  map.resources :source_types, :only => [:index]

  map.resources :activities, :only => [:index], :collection => { :list => :get }
  map.resources :places, :only => [:index], :collection => {
    :cities => :get,
    :countries => :get,
    }
  map.resources :langs, :only => [:index]

  # Non-Resourceful Routes
  map.root :controller => "site", :action => "dashboard"
  map.connect 'about', :controller => "site", :action => "about"
  map.connect 'parse_textile', :controller => 'site', :action => 'parse_textile'

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
end

